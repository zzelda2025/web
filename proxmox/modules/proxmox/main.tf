# ==============================================================
# modules/proxmox/main.tf — Tạo VM Database trên Proxmox
# Provider: bpg/proxmox ~> 0.66.0
# ==============================================================

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }
}
resource "proxmox_virtual_environment_vm" "db_server" {

  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id

  clone {
    vm_id   = var.template_vm_id
    full    = false
    retries = 3
  }

  timeout_clone  = 3600
  timeout_create = 3600

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  agent {
    enabled = false
  }

  # Cloud-Init: Gán IP tĩnh + User/Password
  initialization {
    user_account {
      username = var.vm_user
      password = var.vm_password
    }

    ip_config {
      ipv4 {
        address = var.vm_ip_address
        gateway = var.vm_gateway
      }
    }
  }

  started         = true
  on_boot         = true
  stop_on_destroy = true
}

# ==============================================================
# Provisioner: Chờ cloud-init xong trước khi cài đặt
# ==============================================================
resource "null_resource" "wait_for_cloudinit" {
  triggers = {
    vm_id = proxmox_virtual_environment_vm.db_server.id
  }

  connection {
    type     = "ssh"
    host     = var.vm_ip_raw
    user     = var.vm_user
    password = var.vm_password
    timeout  = "10m"  # Chờ tối đa 10 phút để SSH sẵn sàng
  }

  provisioner "remote-exec" {
    inline = [
      # Chờ cloud-init chạy xong hoàn toàn
      "sudo cloud-init status --wait",
      "echo 'Cloud-init done, VM is ready!'"
    ]
  }

  depends_on = [proxmox_virtual_environment_vm.db_server]
}

# ==============================================================
# Provisioner: Cài PostgreSQL sau khi VM boot
# ==============================================================
resource "null_resource" "install_postgresql" {
  triggers = {
    vm_id = proxmox_virtual_environment_vm.db_server.id
  }

  connection {
    type     = "ssh"
    host     = var.vm_ip_raw
    user     = var.vm_user
    password = var.vm_password
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "echo '=== Disabling needrestart to prevent interactive prompts ==='",
      "sudo mkdir -p /etc/needrestart/conf.d",
      "echo \"\\$nrconf{restart} = 'a';\" | sudo tee /etc/needrestart/conf.d/autorestart.conf",
      "echo \"\\$nrconf{kernelhints} = 0;\" | sudo tee -a /etc/needrestart/conf.d/autorestart.conf",
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' postgresql postgresql-contrib wireguard",
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql",
      "sudo systemctl status postgresql --no-pager",
      "sudo -u postgres psql -c \"CREATE USER appuser WITH PASSWORD '${var.db_password}';\" || echo 'User may already exist'",
      "sudo -u postgres psql -c \"CREATE DATABASE appdb OWNER appuser;\" || echo 'DB may already exist'",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;\"",
      "sudo sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '*'/\" /etc/postgresql/*/main/postgresql.conf",
      "echo 'host appdb appuser 9.9.9.0/24 md5' | sudo tee -a /etc/postgresql/*/main/pg_hba.conf",
      "echo 'host appdb appuser 10.10.10.1/32 md5' | sudo tee -a /etc/postgresql/*/main/pg_hba.conf",
      "echo 'host appdb appuser 10.10.10.2/32 md5' | sudo tee -a /etc/postgresql/*/main/pg_hba.conf",
      "sudo systemctl restart postgresql",
      "echo '=== PostgreSQL setup complete! ==='"
    ]
  }

  depends_on = [null_resource.wait_for_cloudinit]
}

# ==============================================================
# Provisioner: Cài WireGuard sau khi PostgreSQL xong
# ==============================================================
resource "null_resource" "install_wireguard" {
  triggers = {
    vm_id = proxmox_virtual_environment_vm.db_server.id
  }

  connection {
    type     = "ssh"
    host     = var.vm_ip_raw
    user     = var.vm_user
    password = var.vm_password
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/wireguard",
      "printf '[Interface]\nPrivateKey = ${var.wg_proxmox_private_key}\nAddress    = 10.10.10.2/24\n\n[Peer]\nPublicKey  = ${var.wg_ec2_public_key}\nEndpoint   = ${var.wg_ec2_endpoint}:51820\nAllowedIPs = 10.10.10.1/32\nPersistentKeepalive = 25\n' | sudo tee /etc/wireguard/wg0.conf",
      "sudo chmod 600 /etc/wireguard/wg0.conf",
      "sudo systemctl enable wg-quick@wg0",
      "sudo systemctl start wg-quick@wg0",
      "sudo wg show",
      "echo 'WireGuard setup complete!'"
    ]
  }

  depends_on = [null_resource.install_postgresql]
}

# ==============================================================
# Output
# ==============================================================
output "vm_ip" {
  description = "IP tĩnh đã gán cho VM Database"
  value       = var.vm_ip_address
}
