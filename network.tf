module "aws_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = format("%s-vpc", var.prefix)
  cidr = var.vpc_cidr

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = [cidrsubnet(var.vpc_cidr, 3, 2), cidrsubnet(var.vpc_cidr, 3, 3)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 3, 0), cidrsubnet(var.vpc_cidr, 3, 1)]
  intra_subnets   = [cidrsubnet(var.vpc_cidr, 3, 4), cidrsubnet(var.vpc_cidr, 3, 5)]

  enable_nat_gateway = true
  single_nat_gateway = true
}