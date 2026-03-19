# ==============================================================
# variables.tf — Khai báo biến tổng (Root Level)
# ==============================================================
# ✅ Giá trị thực được truyền qua 2 nguồn:
#   1. terraform.tfvars      → biến không nhạy cảm (vmid, node...)
#   2. HCP Terraform UI      → Sensitive Variables (token, password)

# ── Proxmox Connection ─────────────────────────────────────────

variable "proxmox_endpoint" {
  description = "URL API Proxmox. Ví dụ: https://192.168.1.10:8006"
  type        = string
}

variable "proxmox_api_token" {
  description = <<-EOT
    API Token của Proxmox.
    Format: "user@pam!token-name=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    ⚠️  Khai báo là Sensitive Variable trên HCP Terraform UI.
  EOT
  type      = string
  sensitive = true
}

variable "proxmox_ssh_user" {
  description = "User SSH để bpg/proxmox thực hiện các tác vụ cần SSH (cloud-init, upload)"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "Mật khẩu SSH của Proxmox host. Khai báo Sensitive trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

# ── Proxmox VM Config ──────────────────────────────────────────

variable "proxmox_node" {
  description = "Tên node Proxmox sẽ tạo VM. Xem tại giao diện Proxmox (thường là 'pve')"
  type        = string
  default     = "pve"
}

variable "vm_id" {
  description = "VM ID cho Database VM (phải unique trong Proxmox cluster)"
  type        = number
  default     = 200
}

variable "template_vm_id" {
  description = "VM ID của template dùng để clone (phải tồn tại trước trên Proxmox)"
  type        = number
  default     = 201
}

variable "vm_name" {
  description = "Tên hiển thị của VM trên Proxmox"
  type        = string
  default     = "database-vm"
}

variable "vm_ip_address" {
  description = "IP tĩnh gán cho VM. Ví dụ: '192.168.1.100/24'"
  type        = string
}

variable "vm_gateway" {
  description = "Default gateway của VM. Ví dụ: '192.168.1.1'"
  type        = string
}

# ── VM Credentials (Sensitive) ─────────────────────────────────

variable "vm_user" {
  description = "Username SSH vào VM Database"
  type        = string
  default     = "vinh"
}

variable "vm_password" {
  description = "Password SSH vào VM. Khai báo Sensitive trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password PostgreSQL user 'appuser'. Khai báo Sensitive trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

variable "vm_ip_raw" {
  description = "IP không kèm prefix, dùng cho SSH provisioner. Ví dụ: '9.9.9.230'"
  type        = string
}

# ── WireGuard (Sensitive) ──────────────────────────────────────

variable "wg_proxmox_private_key" {
  description = "WireGuard private key của Proxmox VM. Khai báo Sensitive trên HCP Terraform UI."
  type        = string
  sensitive   = true
}

variable "wg_proxmox_public_key" {
  description = "WireGuard public key của Proxmox VM."
  type        = string
}

variable "wg_ec2_public_key" {
  description = "WireGuard public key của EC2 (lấy từ AWS workspace)."
  type        = string
}
