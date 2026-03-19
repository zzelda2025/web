# ==============================================================
# terraform.tfvars — Giá trị biến AWS
# ==============================================================
# ⚠️  KHÔNG commit lên Git
# Sensitive variables set trên HCP Terraform UI:
#   AWS_ACCESS_KEY_ID       (Environment, Sensitive)
#   AWS_SECRET_ACCESS_KEY   (Environment, Sensitive)
#   db_password             (Terraform, Sensitive)

aws_region           = "ap-southeast-1"
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr_1 = "10.0.1.0/24"
public_subnet_cidr_2 = "10.0.2.0/24"
instance_type        = "t3.micro"
key_pair_name        = "devops-htv-key"
