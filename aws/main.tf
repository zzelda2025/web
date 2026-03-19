# ==============================================================
# main.tf — Root: Gọi Module AWS
# ==============================================================

module "aws_web" {
  source = "./modules/aws"

  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr_1 = var.public_subnet_cidr_1
  public_subnet_cidr_2 = var.public_subnet_cidr_2
  instance_type        = var.instance_type
  key_pair_name        = var.key_pair_name
  db_password          = var.db_password
  wg_ec2_private_key   = var.wg_ec2_private_key
  wg_ec2_public_key    = var.wg_ec2_public_key
  wg_proxmox_public_key = var.wg_proxmox_public_key
}

# ==============================================================
# Outputs — Yêu cầu đồ án: output DNS của ALB
# ==============================================================
output "alb_dns_name" {
  description = "DNS của ALB — truy cập web qua đây"
  value       = module.aws_web.alb_dns_name
}

output "ec2_public_ip" {
  description = "Public IP cố định (EIP) của EC2 — dùng làm WireGuard endpoint cho Proxmox"
  value       = module.aws_web.ec2_public_ip
}
