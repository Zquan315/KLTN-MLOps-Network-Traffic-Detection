output "asg_name" {
  value = module.asg_module_monitoring.asg_name
}

output "alb_dns_name" {
  value = module.alb_module_monitoring.alb_dns_name
}