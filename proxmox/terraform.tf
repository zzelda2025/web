# ==============================================================
# terraform.tf — Cấu hình HCP Terraform & Provider
# ==============================================================

terraform {
  # Kết nối HCP Terraform để quản lý State
  # ⚠️  Vào UI HCP Terraform → Workspace "website" → Settings
  #     → Execution Mode → chọn "Local"
  cloud {
    organization = "Devops-HTV"
    workspaces {
      name = "proxmox-infra"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }

  required_version = ">= 1.6.0"
}

# ==============================================================
# Remote State — Đọc output EIP từ AWS workspace
# ==============================================================
data "terraform_remote_state" "aws" {
  backend = "remote"

  config = {
    organization = "Devops-HTV"
    workspaces = {
      name = "aws-infra"
    }
  }
}

# ==============================================================
# Provider Proxmox
# Credentials đọc từ variable — KHÔNG hardcode ở đây
# ==============================================================
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true  # Cho phép self-signed SSL cert của Proxmox

  ssh {
    agent    = false
    username = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }
}
