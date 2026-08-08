# terraform-aws-vpc

A Terraform module that provisions a production-ready AWS VPC with public and private subnets across three availability zones, an internet gateway, and a NAT gateway.

## Requirements

- Terraform >= 1.3.0
- AWS provider >= 5.0.0

## Usage

```hcl
module "vpc" {
  source        = "farrukh90/vpc/aws"
  region        = "us-east-1"
  vpc_cidr      = "10.0.0.0/16"
  public_cidr1  = "10.0.101.0/24"
  public_cidr2  = "10.0.102.0/24"
  public_cidr3  = "10.0.103.0/24"
  private_cidr1 = "10.0.1.0/24"
  private_cidr2 = "10.0.2.0/24"
  private_cidr3 = "10.0.3.0/24"
  tags = {
    Name        = "Project"
    Environment = "Dev"
    Team        = "DevOps"
    Created_by  = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `region` | AWS region to deploy resources into | `string` | yes |
| `vpc_cidr` | CIDR block for the VPC | `string` | yes |
| `public_cidr1` | CIDR block for public subnet 1 (AZ index 0) | `string` | yes |
| `public_cidr2` | CIDR block for public subnet 2 (AZ index 1) | `string` | yes |
| `public_cidr3` | CIDR block for public subnet 3 (AZ index 2) | `string` | yes |
| `private_cidr1` | CIDR block for private subnet 1 (AZ index 0) | `string` | yes |
| `private_cidr2` | CIDR block for private subnet 2 (AZ index 1) | `string` | yes |
| `private_cidr3` | CIDR block for private subnet 3 (AZ index 2) | `string` | yes |
| `tags` | Map of tags to apply to all resources | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the VPC |
| `public_subnets` | List of 3 public subnet IDs (one per AZ) |
| `private_subnets` | List of 3 private subnet IDs (one per AZ) |
| `nat_gateway_id` | ID of the NAT Gateway |
| `nat_gateway_public_ip` | Public IP address of the NAT Gateway |
| `region` | AWS region where the VPC is deployed |
| `tags` | Tags applied to all resources |
| `availability_zones` | List of availability zone names used by the subnets |

## Example output references

```hcl
output "vpc_id"           { value = module.vpc.vpc_id }
output "public_subnet1"   { value = module.vpc.public_subnets[0] }
output "public_subnet2"   { value = module.vpc.public_subnets[1] }
output "public_subnet3"   { value = module.vpc.public_subnets[2] }
output "private_subnet1"  { value = module.vpc.private_subnets[0] }
output "private_subnet2"  { value = module.vpc.private_subnets[1] }
output "private_subnet3"  { value = module.vpc.private_subnets[2] }
output "nat_gateway_ip"   { value = module.vpc.nat_gateway_public_ip }
output "region"           { value = module.vpc.region }
```
