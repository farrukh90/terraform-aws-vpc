variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The vpc_cidr value must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "public_cidr1" {
  description = "CIDR block for public subnet 1 (AZ index 0)."
  type        = string
}

variable "public_cidr2" {
  description = "CIDR block for public subnet 2 (AZ index 1)."
  type        = string
}

variable "public_cidr3" {
  description = "CIDR block for public subnet 3 (AZ index 2)."
  type        = string
}

variable "private_cidr1" {
  description = "CIDR block for private subnet 1 (AZ index 0)."
  type        = string
}

variable "private_cidr2" {
  description = "CIDR block for private subnet 2 (AZ index 1)."
  type        = string
}

variable "private_cidr3" {
  description = "CIDR block for private subnet 3 (AZ index 2)."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
