region   = "us-east-1"
vpc_cidr = "10.2.0.0/16"

public_cidr1 = "10.2.101.0/24"
public_cidr2 = "10.2.102.0/24"
public_cidr3 = "10.2.103.0/24"

private_cidr1 = "10.2.1.0/24"
private_cidr2 = "10.2.2.0/24"
private_cidr3 = "10.2.3.0/24"

tags = {
  Name        = "VPC_Project"
  Environment = "prod"
  Team        = "DevOps"
  Created_by  = "Terraform"
  ManagedBy   = "GitHub Actions"
}
