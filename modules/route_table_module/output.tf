output "route_table_private_id" {
  description = "id of the private route table"
  value       = aws_route_table.route_table_private.id
}

output "route_table_public_id" {
  description = "id of the public route table"
  value       = aws_route_table.route_table_public.id
}