# ==============================================================
# modules/aws/variables.tf — Giai đoạn 3
# ==============================================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
}

variable "public_subnet_cidr_1" {
  description = "CIDR Public Subnet 1 (AZ-a)"
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "CIDR Public Subnet 2 (AZ-b)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_pair_name" {
  description = "Tên Key Pair để SSH vào EC2"
  type        = string
}

variable "db_password" {
  description = "Password PostgreSQL user appuser"
  type        = string
  sensitive   = true
}

variable "wg_ec2_private_key" {
  description = "WireGuard private key của EC2 (VPN Server)"
  type        = string
  sensitive   = true
}

variable "wg_ec2_public_key" {
  description = "WireGuard public key của EC2"
  type        = string
}

variable "wg_proxmox_public_key" {
  description = "WireGuard public key của Proxmox VM (VPN Client)"
  type        = string
}
