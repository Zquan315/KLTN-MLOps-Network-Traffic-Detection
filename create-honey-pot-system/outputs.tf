output "alb_dns_name" {
  value = module.alb_module_honey_pot.alb_dns_name
}

output "honeypot_url" {
  value = "https://honeypot.qmuit.id.vn"
}

output "email_api_endpoint" {
  value       = "${aws_apigatewayv2_stage.prod.invoke_url}/send-alert"
  description = "API Gateway endpoint for email alerts"
}