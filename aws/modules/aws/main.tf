# ==============================================================
# modules/aws/main.tf — Giai đoạn 3: VPC + EC2 + ALB + Cloudflare
# ==============================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC ──────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "devops-htv-vpc", Project = "Final-Lab" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "devops-htv-igw", Project = "Final-Lab" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "devops-htv-public-subnet-1", Project = "Final-Lab" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "devops-htv-public-subnet-2", Project = "Final-Lab" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "devops-htv-public-rt", Project = "Final-Lab" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ── Security Groups ───────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "devops-htv-alb-sg"
  description = "Security Group cho ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "devops-htv-alb-sg", Project = "Final-Lab" }
}

resource "aws_security_group" "web" {
  name        = "devops-htv-web-sg"
  description = "Security Group cho Web Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "WireGuard VPN"
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Node.js tu ALB"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "devops-htv-web-sg", Project = "Final-Lab" }
}

# ── EC2 Instance ──────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name

  user_data = templatefile("${path.module}/userdata.sh", {
    db_password           = var.db_password
    wg_ec2_private_key    = var.wg_ec2_private_key
    wg_proxmox_public_key = var.wg_proxmox_public_key
  })

  tags = {
    Name    = "devops-htv-web-server"
    Project = "Final-Lab"
  }
}

# ── ALB ───────────────────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "devops-htv-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = { Name = "devops-htv-alb", Project = "Final-Lab" }
}

resource "aws_lb_target_group" "web" {
  name     = "devops-htv-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
  }

  tags = { Name = "devops-htv-tg", Project = "Final-Lab" }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 3000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ── Elastic IP ───────────────────────────────────────────────
resource "aws_eip" "web" {
  domain = "vpc"
  tags   = { Name = "devops-htv-eip", Project = "Final-Lab" }
}

resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}

# ==============================================================
# Outputs
# ==============================================================
output "alb_dns_name" {
  description = "DNS cua ALB"
  value       = aws_lb.main.dns_name
}

output "ec2_public_ip" {
  description = "Public IP co dinh (EIP) cua EC2"
  value       = aws_eip.web.public_ip
}
