# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A reusable Terraform module published to the Terraform registry as `farrukh90/vpc/aws`. It provisions an AWS VPC with three public subnets spread across three availability zones, an internet gateway, and a route table. The module is consumed by other projects — changes here affect downstream users.

## Commands

```bash
# Initialize (required before plan/apply)
terraform init

# Validate configuration syntax
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Format all .tf files
terraform fmt -recursive
```

The Jenkins CI pipeline (see `Jenkinsfile`) runs `terraform init` then `terraform apply -auto-approve` inside a Docker container pulled from AWS ECR (`<AWS_ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/tools:latest`). The AWS account ID is passed as the `AWS_ACCOUNT` Jenkins parameter (default: `713287746880`).

## Architecture

| File | Purpose |
|------|---------|
| `provider.tf` | AWS provider, region sourced from `var.region` |
| `vpc.tf` | `aws_vpc.main` — DNS support and hostnames enabled |
| `public_subnet.tf` | Three public subnets (`public1/2/3`), each in a different AZ, `map_public_ip_on_launch = true` |
| `rt_table.tf` | Single public route table (0.0.0.0/0 → IGW), associated with all three subnets; `aws_internet_gateway.gw` |
| `data.tf` | `aws_availability_zones.available` — AZ names indexed into subnets |
| `variable.tf` | Required inputs: `vpc_cidr`, `public_cidr1/2/3`, `tags` (map), `region` |
| `output.tf` | Outputs: `vpc` (ID), `public_subnets` (list of 3 IDs), `region`, `Tags`, `AZ` |
| `terraform.auto.tfvars` | Default values used when running locally — region `us-east-1`, VPC `10.0.0.0/16`, public subnets `10.0.101-103.0/24` |

Note: `terraform.auto.tfvars` also declares `private_cidr1/2/3` variables, but no private subnet resources exist yet — those variables are unused.

## Module Usage (for callers)

```hcl
module "vpc" {
  source       = "farrukh90/vpc/aws"
  region       = "us-east-1"
  vpc_cidr     = "10.0.0.0/16"
  public_cidr1 = "10.0.1.0/24"
  public_cidr2 = "10.0.2.0/24"
  public_cidr3 = "10.0.3.0/24"
  tags = {
    Name        = "Project"
    Environment = "Dev"
    Team        = "DevOps"
    Created_by  = "Terraform"
  }
}
```

Use `module.vpc.public_subnets[0/1/2]` to reference individual subnet IDs.
