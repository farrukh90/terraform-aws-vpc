variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_cidr1" {
  type = string
}

variable "public_cidr2" {
  type = string
}

variable "public_cidr3" {
  type = string
}

variable "private_cidr1" {
  type = string
}

variable "private_cidr2" {
  type = string
}

variable "private_cidr3" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
