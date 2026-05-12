output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs."
  value       = module.vpc.private_subnets
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = module.vpc.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway."
  value       = module.vpc.nat_gateway_public_ip
}

output "availability_zones" {
  description = "Availability zones used by the subnets."
  value       = module.vpc.availability_zones
}
