# khởi tạo tfstate cho workspace khác
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-9999"
    key    = "create-honey-pot-system/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-9999"
    key    = "create-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

# Create ALB and Target Groups 
module "alb_module_honey_pot" {
  source = "../modules/alb_module"
  alb_name              = "alb-honey-pot" 
  load_balancer_type    = var.load_balancer_type_value
  alb_security_group_id = [data.terraform_remote_state.infra.outputs.sg_alb_id]
  public_subnet_ids     = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[3]
  ]

  vpc_id                = data.terraform_remote_state.infra.outputs.vpc_id
  http_port             = var.http_port_value

  routes = [
    { name = "honey-pot",     port = 5500, path_patterns = ["/"],        health_path = "/health",      matcher = "200" },
    { name = "metrics-honey-pot", port = 9100, path_patterns = ["/metrics"], health_path = "/metrics", matcher = "200" }
  ]
  default_route_name = "honey-pot"
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

  name_instance             = "honey-pot-instance" 
  user_data_path            = var.user_data_path_value 

  subnet_ids                = [
    data.terraform_remote_state.infra.outputs.subnet_public_ids[0],
    data.terraform_remote_state.infra.outputs.subnet_public_ids[3]
  ]

  target_group_arns = [
    module.alb_module_honey_pot.tg_arns["honey-pot"],
    module.alb_module_honey_pot.tg_arns["metrics-honey-pot"]
  ]  
}

module "email_lambda" {
  source = "../modules/lambda_module"
  function_name     = var.function_name_value
  source_file_path  = var.lambda_source_file_path_value
}

# API Gateway cho Lambda
resource "aws_apigatewayv2_api" "email_api" {
  name          = "ids-email-alert-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.email_api.id
  integration_type = "AWS_PROXY"
  
  integration_uri    = module.email_lambda.function_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post" {
  api_id    = aws_apigatewayv2_api.email_api.id
  route_key = "POST /send-alert"
  
  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.email_api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.email_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_apigatewayv2_api.email_api.execution_arn}/*/*/send-alert"
}