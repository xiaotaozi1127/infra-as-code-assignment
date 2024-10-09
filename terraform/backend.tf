terraform {
  backend "s3" {
    bucket = "tw-infra-taohui-tfstate"
    key    = "ap-southeast-2/iac-demo/terraform.tfstate"
    region = "ap-southeast-2"

    dynamodb_table = "tw-infra-taohui-tfstate-locks"
    encrypt        = true
  }
}
