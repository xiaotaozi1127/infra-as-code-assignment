variable "prefix" {
  type        = string
  description = "Prefix to many of the resources created which helps as an identifier, could be company name, solution name, etc"
}

variable "region" {
  type        = string
  description = "Region to deploy the solution"
}

variable "stage_name" {
  type        = string
  description = "Stage of the api gateway deployment"
}

variable "webpages" {
  type = list(any)
}
variable "functions" {
  type = list(any)
}
