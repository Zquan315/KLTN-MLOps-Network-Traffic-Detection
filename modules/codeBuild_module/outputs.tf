output "codebuild-project_name" {
  value       = aws_codebuild_project.codebuild-project.name
  description = "Name of the CodeBuild project"
}

output "codebuild-project_arn" {
  value       = aws_codebuild_project.codebuild-project.arn
  description = "ARN of the CodeBuild project"
}
