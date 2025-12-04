output "ids_api_alb_dns" {
  description = "ALB DNS for IDS API"
  value = try(
    data.kubernetes_ingress_v1.api_ingress.status[0].load_balancer[0].ingress[0].hostname,
    "Pending - ALB not created yet"
  )
}

output "mlflow_alb_dns" {
  description = "ALB DNS for MLflow"
  value = try(
    data.kubernetes_ingress_v1.mlflow_ingress.status[0].load_balancer[0].ingress[0].hostname,
    "Pending - ALB not created yet"
  )
}
