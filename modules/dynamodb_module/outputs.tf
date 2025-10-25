output "dynamodb_table_name" {
  value       = aws_dynamodb_table.ids_flow_logs.name
  description = "Tên của bảng DynamoDB"
}
