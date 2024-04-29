variable "prefix" {
  type        = string
  description = "Prefix for the resources"
}

variable "region" {
  type        = string
  description = "Region where solution deployed"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}