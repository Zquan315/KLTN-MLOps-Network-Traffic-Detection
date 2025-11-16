# khởi tạo tfstate cho workspace khác
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-9999"
    key    = "create-log-system/terraform.tfstate"
    region = "us-east-1"
  }
}

# lấy data từ workspace infra
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-9999"
    key    = "create-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

# Create ALB and Target Groups 
module "alb_module_logs" {
  source = "../modules/alb_module"
  alb_name              = "alb-logs" 
  load_balancer_type    = var.load_balancer_type_value
  alb_security_group_id = [data.terraform_remote_state.infra.outputs.sg_alb_id]
  public_subnet_ids     = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[2]
  ]

  vpc_id                = data.terraform_remote_state.infra.outputs.vpc_id
  http_port             = var.http_port_value

  routes = [
    { name = "frontend", port = 8080, path_patterns = ["/"], health_path = "/", matcher = "200-399" },
    { name = "backend", port = 8081, path_patterns = ["/api/*"], health_path = "/api/health", matcher = "200-399" },
    { name = "metrics-log", port = 9100, path_patterns = ["/metrics"], health_path = "/metrics", matcher = "200"}
  ]
  default_route_name = "frontend"
}

# create auto scaling group
module "asg_module_logs" {
  source = "../modules/asg_module"
  asg_name                  = "asg-logs" 
  ami_id                    = var.ami_id_value
  instance_type             = var.instance_type_value
  key_name                  = var.key_name_value
  ec2_instance_profile_name = data.terraform_remote_state.infra.outputs.instance_profile_name
  subnet_id_public          = data.terraform_remote_state.infra.outputs.subnet_public_ids[2]
  security_group_id_public  = [data.terraform_remote_state.infra.outputs.security_group_public_id]
  volume_size               = var.volume_size_value
  volume_type               = var.volume_type_value
  desired_capacity          = var.desired_capacity_value
  min_size                  = var.min_size_value
  max_size                  = var.max_size_value

  name_instance             = "logs_instance" 
  user_data_path            = var.user_data_path_value 

  subnet_ids                = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[2]
  ]

  target_group_arns = [
    module.alb_module_logs.tg_arns["frontend"],
    module.alb_module_logs.tg_arns["backend"],
    module.alb_module_logs.tg_arns["metrics-log"]
  ]  
}

# module "route53_module_logs" {
#   source = "../modules/route53_module"
#   # Route 53
#   route53_zone_name            = var.route53_zone_name_value
#   route53_record_type          = var.route53_record_type_value
#   route53_record_alias_name    = module.alb_module_logs.alb_dns_name
#   route53_record_alias_zone_id = module.alb_module_logs.alb_zone_id
  
# }

# Create CodeDeploy application and deployment group
module "codeDeploy_module" {
  source = "../modules/codeDeploy_module"
  code_deploy_app_name        = var.code_deploy_app_name_value
  compute_platform            = var.compute_platform_value
  deployment_group_name       = var.deployment_group_name_value
  code_deploy_role_arn        = data.terraform_remote_state.infra.outputs.codeDeploy_role_arn
  deployment_option           = var.deployment_option_value
  autoscaling_groups          = [module.asg_module_logs.asg_name]
  target_group_name           = [module.alb_module_logs.tg_names["backend"]]
}

# Create CodeBuild project
module "codeBuild_module" {
  source = "../modules/codeBuild_module"
  project_name                     = var.code_build_project_name_value
  service_role_arn                 = data.terraform_remote_state.infra.outputs.codebuild_role_arn
}

# Create CodePipeline
module "codePipeline_module" {
  source = "../modules/codePipeline_module"
  pipeline_name                   = var.code_pipeline_name_value
  role_arn                        = data.terraform_remote_state.infra.outputs.code_pipeline_role_arn
  s3_bucket                       = data.terraform_remote_state.infra.outputs.s3_bucket_bucket
  build_project_name              = module.codeBuild_module.codebuild-project_name
  application_name                = module.codeDeploy_module.code_deploy_app_name
  deployment_group_name           = module.codeDeploy_module.code_deploy_deployment_group_name
}