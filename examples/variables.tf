variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_cidr1" {
  description = "CIDR block for public subnet 1."
  type        = string
}

variable "public_cidr2" {
  description = "CIDR block for public subnet 2."
  type        = string
}

variable "public_cidr3" {
  description = "CIDR block for public subnet 3."
  type        = string
}

variable "private_cidr1" {
  description = "CIDR block for private subnet 1."
  type        = string
}

variable "private_cidr2" {
  description = "CIDR block for private subnet 2."
  type        = string
}

variable "private_cidr3" {
  description = "CIDR block for private subnet 3."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
