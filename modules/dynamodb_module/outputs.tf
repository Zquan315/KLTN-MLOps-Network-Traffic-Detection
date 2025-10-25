output "dynamodb_table_name" {
  value       = aws_dynamodb_table.ids_log_system.name
  description = "Tên của bảng DynamoDB"
}
