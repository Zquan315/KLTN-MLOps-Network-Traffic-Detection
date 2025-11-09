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

#SQS
output "sqs_queue_arn" {
  value = module.sqs_module.queue_arn
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue for alerts"
  value       = module.sqs_module.queue_url
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

