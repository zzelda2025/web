# ==============================================================
# main.tf — Root: Gọi Module Proxmox
# ==============================================================

module "proxmox_db" {
  source = "./modules/proxmox"

  # Node & VM identity
  node_name      = var.proxmox_node
  vm_id          = var.vm_id
  vm_name        = var.vm_name
  template_vm_id = var.template_vm_id

  # Network
  vm_ip_address = var.vm_ip_address
  vm_ip_raw     = var.vm_ip_raw
  vm_gateway    = var.vm_gateway

  # Credentials
  vm_user     = var.vm_user
  vm_password = var.vm_password
  db_password = var.db_password

  # WireGuard — EIP lấy tự động từ AWS workspace output
  wg_proxmox_private_key = var.wg_proxmox_private_key
  wg_proxmox_public_key  = var.wg_proxmox_public_key
  wg_ec2_public_key      = var.wg_ec2_public_key
  wg_ec2_endpoint        = try(data.terraform_remote_state.aws.outputs.ec2_public_ip, "")
}

# ==============================================================
# Output
# ==============================================================
output "database_vm_ip" {
  description = "Địa chỉ IP nội bộ của VM Database trên Proxmox"
  value       = module.proxmox_db.vm_ip
}
