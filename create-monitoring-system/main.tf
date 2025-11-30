# khởi tạo tfstate cho workspace khác
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-9999"
    key    = "create-monitoring-system/terraform.tfstate"
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
# lấy data từ workspace ids
data "terraform_remote_state" "ids" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-9999"
    key    = "create-ids-system/terraform.tfstate"
    region = "us-east-1"
  }
}

# # lấy data từ workspace honey_pot
# data "terraform_remote_state" "honey_pot" {
#   backend = "s3"
#   config = {
#    bucket = "terraform-state-bucket-9999"
#     key    = "create-honey-pot-system/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

# Lấy data từ log workspace
data "terraform_remote_state" "logs" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-9999"
    key    = "create-log-system/terraform.tfstate"
    region = "us-east-1"
  }
}

# Create ALB and Target Groups 
module "alb_module_monitoring" {
  source = "../modules/alb_module"
  alb_name              = "alb-monitoring" 
  load_balancer_type    = var.load_balancer_type_value
  alb_security_group_id = [data.terraform_remote_state.infra.outputs.sg_alb_id]
  public_subnet_ids     = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[1],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[2]
  ]

  vpc_id                = data.terraform_remote_state.infra.outputs.vpc_id
  http_port             = var.http_port_value

  routes = [
    { name = "prometheus", port = 9090, path_patterns = ["/prometheus", "/prometheus/*"], health_path = "/prometheus", matcher = "200-399" },
    { name = "grafana", port = 3000, path_patterns = ["/"], health_path = "/", matcher = "200" },
    { name = "metrics-monitor", port = 9100, path_patterns = ["/metrics"], health_path = "/metrics", matcher = "200" }
  ]
  default_route_name = "grafana"
}

# create auto scaling group
module "asg_module_monitoring" {
  source = "../modules/asg_module"
  asg_name                  = "asg-monitoring" 
  ami_id                    = var.ami_id_value
  instance_type             = var.instance_type_value
  key_name                  = var.key_name_value
  ec2_instance_profile_name = data.terraform_remote_state.infra.outputs.instance_profile_name
  subnet_id_public          = data.terraform_remote_state.infra.outputs.subnet_public_ids[1]
  security_group_id_public  = [data.terraform_remote_state.infra.outputs.security_group_public_id]
  volume_size               = var.volume_size_value
  volume_type               = var.volume_type_value
  desired_capacity          = var.desired_capacity_value
  min_size                  = var.min_size_value
  max_size                  = var.max_size_value

  name_instance             = "monitoring_instance" 
  user_data_path            = var.user_data_path_value
  user_data_template_vars = {
    IDS_URL = "ids.qmuit.id.vn"
    LOG_URL = "logs.qmuit.id.vn"
    MONITOR_URL = "monitoring.qmuit.id.vn"
    API_URL = "api.qmuit.id.vn"
    HONEYPOT_URL = "honeypot.qmuit.id.vn"
  }

  subnet_ids                = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[1],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[2]
  ]

  target_group_arns = [
    module.alb_module_monitoring.tg_arns["grafana"],
    module.alb_module_monitoring.tg_arns["prometheus"],
    module.alb_module_monitoring.tg_arns["metrics-monitor"]
  ]  
}

# module "route53_module_monitoring" {
#   source = "../modules/route53_module"
#   # Route 53
#   route53_zone_name            = var.route53_zone_name_value
#   route53_record_type          = var.route53_record_type_value
#   route53_record_alias_name    = module.alb_module_monitoring.alb_dns_name
#   route53_record_alias_zone_id = module.alb_module_monitoring.alb_zone_id
  
# }