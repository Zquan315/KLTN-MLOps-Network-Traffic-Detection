# khởi tạo tfstate cho workspace khác
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-9999"
    key    = "create-honey-pot-system/terraform.tfstate"
    region = "us-east-1"
  }
}


# Create ALB and Target Groups 
module "alb_module_honey_pot" {
  source = "../modules/alb_module"
  alb_name              = "alb-honey_pot" 
  load_balancer_type    = var.load_balancer_type_value
  alb_security_group_id = [data.terraform_remote_state.infra.outputs.sg_alb_id]
  public_subnet_ids     = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[3]
  ]

  vpc_id                = data.terraform_remote_state.infra.outputs.vpc_id
  http_port             = var.http_port_value

  routes = [
    { name = "honey_pot",     port = 5500, path_patterns = ["/"],        health_path = "/",      matcher = "200" },
    { name = "metrics-honeypot", port = 9100, path_patterns = ["/metrics"], health_path = "/metrics", matcher = "200" }
  ]
  default_route_name = "honey_pot"
}

# create auto scaling group
module "asg_module_honey_pot" {
  source = "../modules/asg_module"
  asg_name                  = "asg-honey_pot" 
  ami_id                    = var.ami_id_value
  instance_type             = var.instance_type_value
  key_name                  = var.key_name_value
  ec2_instance_profile_name = data.terraform_remote_state.infra.outputs.instance_profile_name
  subnet_id_public          = data.terraform_remote_state.infra.outputs.subnet_public_ids[3]
  security_group_id_public  = [data.terraform_remote_state.infra.outputs.security_group_public_id]
  volume_size               = var.volume_size_value
  volume_type               = var.volume_type_value
  desired_capacity          = var.desired_capacity_value
  min_size                  = var.min_size_value
  max_size                  = var.max_size_value

  name_instance             = "honey_pot_instance" 
  user_data_path            = var.user_data_path_value 

  subnet_ids                = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[3]
  ]

  target_group_arns = [
    module.alb_module_honey_pot.tg_arns["honey_pot"],
    module.alb_module_honey_pot.tg_arns["metrics-honeypot"]
  ]  
}