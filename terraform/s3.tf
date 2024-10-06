module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.website_bucket_name
}
