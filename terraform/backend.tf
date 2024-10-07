terraform {
  backend "s3" {
    bucket = "tw-iac-demo-taohui-tfstate"
    key    = "ap-southeast-2/iac-demo/terraform.tfstate"
    region = "ap-southeast-2"

    dynamodb_table = "tw-iac-demo-tfstate-locks-taohui"
    encrypt        = true
  }
}
