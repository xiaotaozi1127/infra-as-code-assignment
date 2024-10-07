module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"
  bucket = format("%s-website_bucket", var.prefix)
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"
}

# Reference the outputs from the module
output "website_bucket_name" {
  value = module.s3_bucket.s3_bucket_arn
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "index.html"  # The name of the object in the S3 bucket
  source = "index.html"  # Path to the local file you want to upload
  acl    = "private"
}

resource "aws_s3_bucket_object" "error_html" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "error.html"  # The name of the object in the S3 bucket
  source = "error.html"  # Path to the local file you want to upload
  acl    = "private"
}
