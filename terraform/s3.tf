module "s3_bucket" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"
  bucket  = format("%s-website-bucket", var.prefix)
  acl     = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"
}

resource "aws_s3_object" "webpages" {
  depends_on = [module.s3_bucket]
  bucket     = format("%s-website-bucket", var.prefix)
  count      = length(var.webpages)

  key    = var.webpages[count.index].name
  source = var.webpages[count.index].name
}
