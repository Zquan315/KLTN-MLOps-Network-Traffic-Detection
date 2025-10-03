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