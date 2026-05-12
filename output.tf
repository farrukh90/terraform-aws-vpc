output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of public subnet IDs (one per AZ)."
  value = [
    aws_subnet.public1.id,
    aws_subnet.public2.id,
    aws_subnet.public3.id,
  ]
}

output "private_subnets" {
  description = "List of private subnet IDs (one per AZ)."
  value = [
    aws_subnet.private1.id,
    aws_subnet.private2.id,
    aws_subnet.private3.id,
  ]
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway Elastic IP."
  value       = aws_eip.nat.public_ip
}

output "region" {
  description = "AWS region where the VPC is deployed."
  value       = var.region
}

output "tags" {
  description = "Tags applied to all resources."
  value       = var.tags
}

output "availability_zones" {
  description = "List of availability zone names used by the subnets."
  value       = data.aws_availability_zones.available.names
}
