output "code_deploy_app_arn" {
  description = "The ARN of the CodeDeploy app role created by the module."
  value       = aws_codedeploy_app.code_deploy_app.arn
}

output "code_deploy_deployment_group_arn" {
  description = "The ARN of the CodeDeploy deployment group created by the module."
  value       = aws_codedeploy_deployment_group.code_deploy_deployment_group.arn
}

output "code_deploy_app_name" {
  description = "The name of the CodeDeploy app role created by the module."
  value       = aws_codedeploy_app.code_deploy_app.name
}

output "code_deploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group created by the module."
  value       = aws_codedeploy_deployment_group.code_deploy_deployment_group.deployment_group_name
}