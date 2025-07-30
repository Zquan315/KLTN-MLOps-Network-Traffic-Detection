output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "subnet_public_ids" {
  description = "The cidr of the public subnets"
  value       = [for subnet in aws_subnet.subnet_public: subnet.id]
}

output "subnet_private_ids" {
  description = "The cidr of the private subnets"
  value       = [for subnet in aws_subnet.subnet_private: subnet.id]
  
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
  
}