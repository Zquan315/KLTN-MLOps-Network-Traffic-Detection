# Output cho IDS API
output "ids_alb_dns_name" {
  description = "The DNS name of the ALB for IDS API"
  value       = try(kubernetes_ingress_v1.ids_ingress.status[0].load_balancer[0].ingress[0].hostname, "Pending - ALB is being created")
}

output "predict_api_endpoint" {
  description = "Public URL for the prediction API"
  value       = try(
    "http://${kubernetes_ingress_v1.ids_ingress.status[0].load_balancer[0].ingress[0].hostname}/predict",
    "Pending - waiting for ALB creation"
  )
}

# Output cho MLflow
output "mlflow_alb_dns_name" {
  description = "The DNS name of the ALB for MLflow"
  value       = try(kubernetes_ingress_v1.mlflow_ingress.status[0].load_balancer[0].ingress[0].hostname, "Pending - ALB is being created")
}

output "mlflow_endpoint" {
  description = "Public URL for the MLflow UI"
  value       = try(
    "http://${kubernetes_ingress_v1.mlflow_ingress.status[0].load_balancer[0].ingress[0].hostname}",
    "Pending - waiting for ALB creation"
  )
}

output "mlflow_artifact_s3_path" {
  description = "S3 path for MLflow artifacts"
  value       = "s3://${data.terraform_remote_state.infra.outputs.api_model_bucket_name}/mlflow-artifacts"
}

# Status của cả 2 Ingress
output "ingress_status" {
  description = "Status of the Ingress resources"
  value = {
    ids_ready   = length(try(kubernetes_ingress_v1.ids_ingress.status[0].load_balancer[0].ingress, [])) > 0
    mlflow_ready = length(try(kubernetes_ingress_v1.mlflow_ingress.status[0].load_balancer[0].ingress, [])) > 0
  }
}