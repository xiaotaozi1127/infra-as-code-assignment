resource "aws_dynamodb_table" "user-info-table" {
  name           = format("%s-user-info-table", var.prefix)
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userid"

  attribute {
    name = "userid"
    type = "S"
  }
}
