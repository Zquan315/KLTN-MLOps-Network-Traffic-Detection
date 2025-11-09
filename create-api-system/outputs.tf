output "eks_cluster_name" {
  description = "Tên của EKS cluster được tạo cho API IDS"
  value       = module.eks.cluster_name
}

output "eks_endpoint" {
  description = "API endpoint của EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "nodegroup_role_arn" {
  value = module.eks.eks_managed_node_groups["api-nodes"].iam_role_arn
}

output "vpc_id" {
  description = "VPC ID được tái sử dụng từ create-infrastructure"
  value       = data.terraform_remote_state.infra.outputs.vpc_id
}

output "api_service_hostname" {
  description = "Public hostname của API Service (LoadBalancer)"
  value       = kubernetes_service.arf_ids_api.status[0].load_balancer[0].ingress[0].hostname
}

output "api_service_port" {
  description = "Port công khai của API Service"
  value       = kubernetes_service.arf_ids_api.spec[0].port[0].port
}

output "api_url" {
  description = "URL endpoint đầy đủ của ARF IDS API"
  value       = "http://${kubernetes_service.arf_ids_api.status[0].load_balancer[0].ingress[0].hostname}/predict"
}

output "api_feedback_url" {
  description = "URL endpoint của Feedback API (dành cho IDS gửi nhãn thật)"
  value       = "http://${kubernetes_service.arf_ids_api.status[0].load_balancer[0].ingress[0].hostname}/feedback"
}

output "api_metrics_endpoint" {
  description = "Endpoint Prometheus sẽ scrape metrics từ API (EKS)"
  value       = "http://${kubernetes_service.arf_ids_api.status[0].load_balancer[0].ingress[0].hostname}/metrics"
}
