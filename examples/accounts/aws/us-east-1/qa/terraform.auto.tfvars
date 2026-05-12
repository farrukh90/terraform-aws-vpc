region   = "us-east-1"
vpc_cidr = "10.1.0.0/16"

public_cidr1 = "10.1.101.0/24"
public_cidr2 = "10.1.102.0/24"
public_cidr3 = "10.1.103.0/24"

private_cidr1 = "10.1.1.0/24"
private_cidr2 = "10.1.2.0/24"
private_cidr3 = "10.1.3.0/24"

tags = {
  Name        = "VPC_Project"
  Environment = "qa"
  Team        = "DevOps"
  Created_by  = "Terraform"
  ManagedBy   = "GitHub Actions"
}
