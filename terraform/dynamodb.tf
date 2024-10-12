resource "aws_dynamodb_table" "user-info-table" {
  name         = format("%s-user-info-table", var.prefix)
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userid"

  //Enable DynamoDB Point-In-Time Recovery (PITR)
  point_in_time_recovery {
    enabled = true
  }

  //Ensuring DynamoDB tables are encrypted with KMS Customer Managed CMKs is crucial for sensitive data requiring stringent compliance and security standards.
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.kms.arn
  }

  attribute {
    name = "userid"
    type = "S"
  }
}

resource "aws_kms_key" "kms" {
  description         = "KMS key for DynamoDB table encryption"
  is_enabled          = true
  enable_key_rotation = true
}

