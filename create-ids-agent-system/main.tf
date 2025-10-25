# khởi tạo tfstate cho workspace khác
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-9999"
    key    = "create-ids-system/terraform.tfstate"
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

#data "terraform_remote_state" "honey_pot" {
  #backend = "s3"
  #config = {
   # bucket = "terraform-state-bucket-9999"
    #key    = "create-honey-pot-system/terraform.tfstate"
    #region = "us-east-1"
  #}
#}

# Create ALB and Target Groups 
module "alb_module_ids" {
  source = "../modules/alb_module"
  alb_name              = "alb-ids" 
  load_balancer_type    = var.load_balancer_type_value
  alb_security_group_id = [data.terraform_remote_state.infra.outputs.sg_alb_id]
  public_subnet_ids     = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[1]
  ]

  vpc_id                = data.terraform_remote_state.infra.outputs.vpc_id
  http_port             = var.http_port_value

  routes = [
    { name = "web",     port = 5001, path_patterns = ["/"],        health_path = "/",      matcher = "200" },
    { name = "metrics", port = 9100, path_patterns = ["/metrics"], health_path = "/metrics", matcher = "200-399" }
  ]
  default_route_name = "web"
}

# create auto scaling group
module "asg_module_ids" {
  source = "../modules/asg_module"
  asg_name                  = "asg-ids" 
  ami_id                    = var.ami_id_value
  instance_type             = var.instance_type_value
  key_name                  = var.key_name_value
  ec2_instance_profile_name = data.terraform_remote_state.infra.outputs.instance_profile_name
  subnet_id_public          = data.terraform_remote_state.infra.outputs.subnet_public_ids[0]
  security_group_id_public  = [data.terraform_remote_state.infra.outputs.security_group_public_id]
  volume_size               = var.volume_size_value
  volume_type               = var.volume_type_value
  desired_capacity          = var.desired_capacity_value
  min_size                  = var.min_size_value
  max_size                  = var.max_size_value

  name_instance             = "ids_instance" 
  user_data_path            = var.user_data_path_value 

  subnet_ids                = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[1]
  ]

  target_group_arns = [
    module.alb_module_ids.tg_arns["web"],
    module.alb_module_ids.tg_arns["metrics"]
  ]  
}

module "route53_module_ids" {
  source = "../modules/route53_module"
  # Route 53
  route53_zone_name            = var.route53_zone_name_value
  route53_record_type          = var.route53_record_type_value
  route53_record_alias_name    = module.alb_module_ids.alb_dns_name
  route53_record_alias_zone_id = module.alb_module_ids.alb_zone_id
  
}