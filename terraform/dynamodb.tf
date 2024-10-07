resource "aws_dynamodb_table" "user-info-table" {
  name           = format("%s-user-info-table", var.prefix)
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}
