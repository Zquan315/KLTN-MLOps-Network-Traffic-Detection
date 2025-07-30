output "codePipeline_name" {
  description = "The name of the created CodePipeline"
  value       = aws_codepipeline.codePipeline.name
}

output "codePipeline_arn" {
  description = "The ARN of the created CodePipeline"
  value       = aws_codepipeline.codePipeline.arn
}