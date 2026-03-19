# ==============================================================
# modules/proxmox/variables.tf
# ==============================================================

variable "node_name" {
  description = "Tên node Proxmox"
  type        = string
}

variable "vm_id" {
  description = "VM ID cho Database VM"
  type        = number
}

variable "vm_name" {
  description = "Tên VM"
  type        = string
}

variable "template_vm_id" {
  description = "VM ID của template để clone"
  type        = number
}

variable "vm_ip_address" {
  description = "IP tĩnh kèm prefix. Ví dụ: '9.9.9.230/24'"
  type        = string
}

variable "vm_ip_raw" {
  description = "IP không kèm prefix, dùng cho SSH. Ví dụ: '9.9.9.230'"
  type        = string
}

variable "vm_gateway" {
  description = "Default gateway. Ví dụ: '9.9.9.254'"
  type        = string
}

variable "vm_user" {
  description = "Username SSH vào VM (Cloud-Init sẽ tạo user này)"
  type        = string
  default     = "vinh"
}

variable "vm_password" {
  description = "Password SSH. Khai báo Sensitive trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password cho PostgreSQL user 'appuser'. Khai báo Sensitive."
  type        = string
  sensitive   = true
}

# ── WireGuard ──────────────────────────────────────────────────

variable "wg_proxmox_private_key" {
  description = "WireGuard private key của Proxmox VM."
  type        = string
  sensitive   = true
}

variable "wg_proxmox_public_key" {
  description = "WireGuard public key của Proxmox VM."
  type        = string
}

variable "wg_ec2_public_key" {
  description = "WireGuard public key của EC2."
  type        = string
}

variable "wg_ec2_endpoint" {
  description = "EIP của EC2 — dùng làm WireGuard endpoint. Lấy tự động từ AWS remote state."
  type        = string
  default     = ""
}
