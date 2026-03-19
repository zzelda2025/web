#!/bin/bash
set -e

# =============================================================
# User Data Script — EC2 Web Server
# Cài: WireGuard (VPN Server) + Node.js + Web App
# =============================================================

apt-get update -y || apt-get update -y
apt-get install -y --fix-missing curl nodejs npm wireguard || (apt-get update -y && apt-get install -y --fix-missing curl nodejs npm wireguard)

# ── Cấu hình WireGuard (EC2 = VPN Server) ────────────────────
# EC2 lắng nghe port 51820, Proxmox VM kết nối vào EIP của EC2

cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
PrivateKey = ${wg_ec2_private_key}
Address    = 10.10.10.1/24
ListenPort = 51820

# Cho phép forward traffic qua VPN
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Proxmox DB VM
PublicKey  = ${wg_proxmox_public_key}
AllowedIPs = 10.10.10.2/32
WGEOF

chmod 600 /etc/wireguard/wg0.conf

# Bật IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Khởi động WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# ── Tạo Node.js Web App ──────────────────────────────────────
mkdir -p /opt/webapp
cd /opt/webapp

cat > package.json << 'PKGJSON'
{
  "name": "devops-htv-webapp",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "pg": "^8.11.0"
  }
}
PKGJSON

cat > app.js << 'APPJS'
const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const pool = new Pool({
  host:            '10.10.10.2',
  port:            5432,
  database:        'appdb',
  user:            'appuser',
  password:        process.env.DB_PASSWORD,
  connectionTimeoutMillis: 5000,  // timeout 5s thay vì treo mãi
  idleTimeoutMillis:       10000,
});

async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100),
      message TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `);
}

app.get('/', async (req, res) => {
  let rows = [];
  let dbStatus = 'connected';
  let errorMsg = '';

  try {
    await initDB();
    const result = await pool.query(
      'SELECT * FROM messages ORDER BY created_at DESC LIMIT 20'
    );
    rows = result.rows;
  } catch (e) {
    dbStatus = 'error';
    errorMsg = e.message;
  }

  const statusBadge = dbStatus === 'connected'
    ? '<span style="color:green">Connected to PostgreSQL on Proxmox</span>'
    : '<span style="color:red">DB Error: ' + errorMsg + '</span>';

  const tableRows = rows.map(function(r) {
    return '<tr><td>' + r.id + '</td><td>' + r.name + '</td><td>' + r.message + '</td><td>' + r.created_at + '</td></tr>';
  }).join('');

  const tableHTML = rows.length === 0
    ? '<p>Chua co du lieu nao.</p>'
    : '<table border="1" cellpadding="8" cellspacing="0" style="width:100%;border-collapse:collapse">'
      + '<tr style="background:#232f3e;color:white"><th>ID</th><th>Ten</th><th>Tin nhan</th><th>Thoi gian</th></tr>'
      + tableRows
      + '</table>';

  res.send(
    '<!DOCTYPE html>'
    + '<html><head><title>DevOps HTV</title>'
    + '<style>'
    + 'body{font-family:Arial;max-width:900px;margin:40px auto;padding:20px}'
    + 'h1{color:#232f3e}'
    + '.badge{background:#ff9900;color:white;padding:4px 10px;border-radius:4px;font-size:12px}'
    + 'form{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'
    + 'input,textarea{width:100%;padding:8px;margin:8px 0;border:1px solid #ddd;border-radius:4px;box-sizing:border-box}'
    + 'button{background:#ff9900;color:white;padding:10px 20px;border:none;border-radius:4px;cursor:pointer}'
    + '.status{padding:10px;border-radius:4px;margin:10px 0;background:#f0f0f0}'
    + '</style></head>'
    + '<body>'
    + '<h1>DevOps HTV <span class="badge">AWS + Proxmox</span></h1>'
    + '<p>Web Server: <b>AWS EC2</b> | Database: <b>PostgreSQL on Proxmox</b></p>'
    + '<div class="status">DB Status: ' + statusBadge + '</div>'
    + '<form method="POST" action="/add">'
    + '<h3>Them du lieu moi</h3>'
    + '<input type="text" name="name" placeholder="Ten cua ban" required />'
    + '<textarea name="message" placeholder="Noi dung tin nhan" rows="3" required></textarea>'
    + '<button type="submit">Them vao Database</button>'
    + '</form>'
    + '<h3>Du lieu trong PostgreSQL (Proxmox)</h3>'
    + tableHTML
    + '</body></html>'
  );
});

app.post('/add', async (req, res) => {
  const name = req.body.name;
  const message = req.body.message;
  try {
    await pool.query(
      'INSERT INTO messages (name, message) VALUES ($1, $2)',
      [name, message]
    );
    res.redirect('/');
  } catch (e) {
    res.send('<p>Error: ' + e.message + '</p><a href="/">Back</a>');
  }
});

app.listen(3000, function() {
  console.log('Server running on port 3000');
});
APPJS

npm install

# ── Tạo service Node.js ───────────────────────────────────────
cat > /etc/systemd/system/webapp.service << SVCEOF
[Unit]
Description=DevOps HTV Web App
After=network.target wg-quick@wg0.service

[Service]
WorkingDirectory=/opt/webapp
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=5
Environment=DB_PASSWORD=${db_password}

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable webapp
systemctl start webapp
