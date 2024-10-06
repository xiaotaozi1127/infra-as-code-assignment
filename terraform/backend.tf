terraform {
  backend "s3" {
    bucket = "tw-infra-taohui-tfstate"
    key    = "ap-southeast-2/iac-infra/terraform.tfstate"
    region = "ap-southeast-2"

    dynamodb_table = "tw-infra-tfstate-locks-taohui"
    encrypt        = true
  }
}
