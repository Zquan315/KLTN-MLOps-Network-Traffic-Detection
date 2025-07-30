output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
  
}

output "tg_frontend_arn" {
  description = "The ARN of the frontend target group"
  value       = aws_lb_target_group.tg_frontend.arn
}

output "tg_backend_arn" {
  description = "The ARN of the backend target group"
  value       = aws_lb_target_group.tg_backend.arn
}

output "tg_backend_name" {
  description = "The name of the backend target group"
  value       = aws_lb_target_group.tg_backend.name
}

output "alb_zone_id" {
  description = "The zone ID of the Application Load Balancer"
  value       = aws_lb.alb.zone_id
  
}