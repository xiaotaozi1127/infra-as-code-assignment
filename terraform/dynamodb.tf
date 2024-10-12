resource "aws_dynamodb_table" "user-info-table" {
  name         = format("%s-user-info-table", var.prefix)
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userid"

  #checkov:skip=CKV_AWS_119:Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK

  //Enable DynamoDB Point-In-Time Recovery (PITR)
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "userid"
    type = "S"
  }
}

