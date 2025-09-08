output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
  
}

output "tg_arns" {
  value = { for k, r in aws_lb_target_group.tg : k => r.arn }
}

output "alb_zone_id" {
  description = "The zone ID of the Application Load Balancer"
  value       = aws_lb.alb.zone_id
  
}