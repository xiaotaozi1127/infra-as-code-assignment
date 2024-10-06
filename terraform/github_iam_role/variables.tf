variable "prefix" {
  type        = string
  description = "Prefix to many of the resources created which helps as an identifier, could be company name, solution name, etc"
  default     = "tw-infra-taohui"
}

variable "repo_name" {
  type        = string
  description = "Name of GitHub repository"
  default     = "xiaotaozi1127/infra-as-code-assignment"
}

variable "region" {
  type        = string
  description = "Region to deploy the solution"
  default     = "ap-southeast-2"
}
