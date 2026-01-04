# VPC + Subnets
output "vpc_id" {
  value = module.vpc_module.vpc_id
}
output "subnet_public_ids" {
  value = module.vpc_module.subnet_public_ids
}
output "subnet_private_ids" {
  value = module.vpc_module.subnet_private_ids
}

# Security Groups
output "sg_alb_id" {
  value = module.security_group_module.sg_alb_id
}
output "security_group_public_id" {
  value = module.security_group_module.security_group_public_id
}
output "security_group_private_id" {
  value = module.security_group_module.security_group_private_id
}

# IAM (theo outputs hiện có trong iam_module)
output "instance_profile_name" {
  value = module.iam_module.instance_profile_name
}

output "codeDeploy_role_arn" {
  value = module.iam_module.codeDeploy_role_arn
}

output "codebuild_role_arn" {
  value = module.iam_module.codebuild_role_arn
}

output "s3_bucket_bucket" {
  value = module.s3_module.s3_bucket_bucket
}


output "code_pipeline_role_arn" {
  value = module.iam_module.code_pipeline_role_arn
}

output "dynamodb_table" {
  value = module.dynamodb_module.dynamodb_table_name
}


# output "ec2_api_public_ip" {
#   value = module.ec2_module.eip_allocate_ec2_api
# }



output "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  value       = module.iam_module.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS node group"
  value       = module.iam_module.eks_node_role_arn
}

output "api_model_bucket_name" {
  description = "Tên bucket dùng cho model API"
  value       = module.s3_api_model_bucket.s3_bucket_bucket
}

output "api_model_bucket_arn" {
  description = "ARN bucket dùng cho model API"
  value       = module.s3_api_model_bucket.s3_bucket_arn
}

output "arf_s3_model_access_policy_arn" {
  value       = aws_iam_policy.arf_s3_model_access.arn
  description = "ARN của policy cho phép đọc model từ S3"
}

# ============================================================
# EKS OUTPUTS
# ============================================================
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Certificate authority data for EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn 
}

# EFS outputs
output "efs_id" {
  description = "The ID of the EFS file system for monitoring"
  value       = module.efs_module.efs_id
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system for monitoring"
  value       = module.efs_module.efs_dns_name
}

output "efs_arn" {
  description = "The ARN of the EFS file system for monitoring"
  value       = module.efs_module.efs_arn
}

output "prometheus_access_point_id" {
  description = "The ID of the Prometheus EFS access point"
  value       = module.efs_module.prometheus_access_point_id
}

output "grafana_access_point_id" {
  description = "The ID of the Grafana EFS access point"
  value       = module.efs_module.grafana_access_point_id
}

output "alertmanager_access_point_id" {
  description = "The ID of the Alertmanager EFS access point"
  value       = module.efs_module.alertmanager_access_point_id
}

output "sg_efs_id" {
  description = "The ID of the security group for EFS"
  value       = module.security_group_module.sg_efs_id
}