output "security_group_private_id" {
  description = "The ID of the security group created"
  value       = aws_security_group.security_group_private.id
}

output "security_group_public_id" {
  description = "The ID of the security group created"
  value       = aws_security_group.security_group_public.id
}

output "sg_alb_id" {
  description = "The ID of the security group created for ALB"
  value       = aws_security_group.sg_alb.id
}