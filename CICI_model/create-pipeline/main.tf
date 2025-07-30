data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket"
    key    = "create-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}


# Create CodeDeploy application and deployment group
module "codeDeploy_module" {
  source = "../../modules/codeDeploy_module"
  code_deploy_app_name        = var.code_deploy_app_name_value
  compute_platform            = var.compute_platform_value
  deployment_group_name       = var.deployment_group_name_value
  code_deploy_role_arn        = data.terraform_remote_state.infra.outputs.codeDeploy_role_arn
  deployment_option           = var.deployment_option_value
  autoscaling_groups          = [data.terraform_remote_state.infra.outputs.asg_name]
  target_group_name           = data.terraform_remote_state.infra.outputs.tg_backend_name
}

# Create CodeBuild project
module "codeBuild_module" {
  source = "../../modules/codeBuild_module"
  project_name                     = var.code_build_project_name_value
  service_role_arn                 = data.terraform_remote_state.infra.outputs.codebuild_role_arn
  s3_bucket                        = data.terraform_remote_state.infra.outputs.bucket_bucket 
  github_repo                      = var.github_repo_value
}

# Create CodePipeline
module "codePipeline_module" {
  source = "../../modules/codePipeline_module"
  pipeline_name                   = var.code_pipeline_name_value
  role_arn                        = data.terraform_remote_state.infra.outputs.code_pipeline_role_arn
  s3_bucket                       = data.terraform_remote_state.infra.outputs.bucket_bucket
  github_repo                     = var.github_repo_value
  github_oauth_token              = var.github_oauth_token_value
  github_owner                    = var.github_owner_value 
  build_project_name              = module.codeBuild_module.codebuild-project_name
  application_name                = module.codeDeploy_module.code_deploy_app_name
  deployment_group_name           = module.codeDeploy_module.code_deploy_deployment_group_name
}