output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb_module_logs.alb_dns_name
}