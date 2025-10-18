output "asg_name" {
  value = module.asg_module_ids.asg_name
}

output "alb_dns" {
  value = module.alb_module_ids.alb_dns_name
}