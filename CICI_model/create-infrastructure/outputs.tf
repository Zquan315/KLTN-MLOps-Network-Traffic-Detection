output "codeDeploy_role_arn" {
  value = module.iam_module.codeDeploy_role_arn
}

output "codebuild_role_arn" {
  value = module.iam_module.codebuild_role_arn
}

output "app_student_bucket_bucket" {
  value = module.s3_module.app_student_bucket_bucket
}


output "code_pipeline_role_arn" {
  value = module.iam_module.code_pipeline_role_arn
}

output "asg_name" {
  value = module.asg_module.asg_name
}

output "tg_backend_name" {
  value = module.alb_module.tg_backend_name
}