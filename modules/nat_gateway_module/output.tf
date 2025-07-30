output "nat_gateway_id" {
  description = "The ID of the NAT Gateway in zone A"
  value       = aws_nat_gateway.nat_gateway.id
}

output "eip_allocate_nat_gateway_id" {
  description = "The ID of the Elastic IP associated with the NAT Gateway"
  value       = aws_eip.eip_allocate_nat_gateway.id
  
}
