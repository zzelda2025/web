# ==============================================================
# variables.tf — Root Level (AWS) Giai đoạn 3
# ==============================================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
  description = "CIDR Public Subnet 1 (AZ-a)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "CIDR Public Subnet 2 (AZ-b)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Tên Key Pair đã tạo trên AWS Console"
  type        = string
}

variable "db_password" {
  description = "Password PostgreSQL user appuser. Set Sensitive Variable trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

variable "wg_ec2_private_key" {
  description = "WireGuard private key của EC2. Set Sensitive Variable trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

variable "wg_ec2_public_key" {
  description = "WireGuard public key của EC2."
  type        = string
}

variable "wg_proxmox_public_key" {
  description = "WireGuard public key của Proxmox VM."
  type        = string
}
