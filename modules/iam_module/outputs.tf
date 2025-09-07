output "ec2_role_arn" {
  description = "The ARN of the IAM role created by the module."
  value       = aws_iam_role.ec2_role.arn
}

output "codeDeploy_role_arn" {
  description = "The ARN of the CodeDeploy IAM role created by the module."
  value       = aws_iam_role.codeDeploy_role.arn
}

output "ec2_role_name" {
  description = "The ARN of the IAM role created by the module."
  value       = aws_iam_role.ec2_role.name
}

output "codeDeploy_role_name" {
  description = "The ARN of the CodeDeploy IAM role created by the module."
  value       = aws_iam_role.codeDeploy_role.name
}

output "instance_profile_name" {
  description = "The name of the IAM instance profile created by the module."
  value       = aws_iam_instance_profile.instance_profile.name
}

output "codebuild_role_arn" {
  description = "The ARN of the CodeBuild IAM role created by the module."
  value       = aws_iam_role.codeBuild_role.arn
}

output "code_pipeline_role_arn" {
  description = "The ARN of the CodePipeline IAM role created by the module."
  value       = aws_iam_role.codePipeline_role.arn
  
}