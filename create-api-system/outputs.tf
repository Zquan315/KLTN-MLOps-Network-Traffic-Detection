output "ids_api_alb_dns" {
  description = "API"
  value = try(
    data.kubernetes_ingress_v1.api_ingress.status[0].load_balancer[0].ingress[0].hostname,
    "Pending"
  )
}

output "mlflow_alb_dns" {
  description = "MLflow"
  value = try(
    data.kubernetes_ingress_v1.mlflow_ingress.status[0].load_balancer[0].ingress[0].hostname,
    "Pending"
  )
}

output "argocd_alb_dns" {
  description = "ArgoCD server"
  value = try(
    data.kubernetes_ingress_v1.argocd_ingress.status[0].load_balancer[0].ingress[0].hostname,
    "Pending"
  )
}

output "argo_workflows_alb_dns" {
  description = "Argo Workflows UI"
  value = try(
    data.kubernetes_ingress_v1.argo_workflows_ingress.status[0].load_balancer[0].ingress[0].hostname,
    "Pending"
  )
}


