# ==============================================================
# terraform.tf — HCP Terraform + AWS Provider
# Workspace: aws-infra | Execution Mode: Remote
# ==============================================================

terraform {
  cloud {
    organization = "Devops-HTV"
    workspaces {
      name = "aws-infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "aws" {
  region = var.aws_region
  # Credentials đọc từ Sensitive Variables trên HCP Terraform UI:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
}
