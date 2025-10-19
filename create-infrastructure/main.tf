terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-9999" 
    key            = "create-infrastructure/terraform.tfstate"
    region         = "us-east-1" 
  }
}

# create VPC and subnets
module "vpc_module" {
  source = "../modules/vpc_module"
  #VPC
  cidr_block_value         = var.vpc_cidr_block_value
  cidr_block_private_value = var.vpc_cidr_block_private_value
  cidr_block_public_value  = var.vpc_cidr_block_public_value
  subnet_count_value       = var.vpc_subnet_count_value
}

# Create Nat Gateway
module "nat_gateway_module" {
  source = "../modules/nat_gateway_module"
  region_network_border_group = var.region_value
  # NAT Gateway
  nat_gateway_subnet_id       = module.vpc_module.subnet_public_ids[0]
}

# create route table
module "route_table_module" {
  source = "../modules/route_table_module"

  # Route Table
  vpc_id_value = module.vpc_module.vpc_id

  # Route Table Private
  destination_cidr_block_private = var.destination_cidr_block_private_value
  gateway_id_private             = module.nat_gateway_module.nat_gateway_id
  subnet_id_private              = [module.vpc_module.subnet_private_ids[0], 
                                    module.vpc_module.subnet_private_ids[1],
                                    module.vpc_module.subnet_private_ids[2],
                                    module.vpc_module.subnet_private_ids[3]]

  # Route Table Public
  destination_cidr_block_public  = var.destination_cidr_block_public_value
  gateway_id_public              = module.vpc_module.internet_gateway_id
  subnet_id_public               = [module.vpc_module.subnet_public_ids[0], 
                                   module.vpc_module.subnet_public_ids[1],
                                   module.vpc_module.subnet_public_ids[2],
                                   module.vpc_module.subnet_public_ids[3]]
}

# Create Security Groups
module "security_group_module" {
  source = "../modules/security_group_module"
  vpc_id = module.vpc_module.vpc_id
  # Security Group Private ingress

  from_port_in_private = var.from_port_in_private_value
  to_port_in_private   = var.to_port_in_private_value
  protocol_in_private  = var.protocol_in_private_value

  # Security Group Public ingress
  ingress_rules_public = var.ingress_rules_public_value

}

# Create S3 bucket
module "s3_module" {
  source = "../modules/s3_module"
  bucket_name_value         = var.s3_bucket_name_value
}

# Create IAM 
module "iam_module" {
  source                             = "../modules/iam_module"
  ec2_role_name                      = var.ec2_role_name_value
  code_deploy_role_name              = var.code_deploy_role_name_value
  readonly_policy_arn                = var.readonly_policy_arn_value
  ec2_code_deploy_policy_arn         = var.ec2_code_deploy_policy_arn_value
  code_deploy_policy_arn             = var.code_deploy_policy_arn_value
  admin_policy_arn                   = var.admin_policy_arn_value
  codebuild_role_name                = var.codebuild_role_name_value
  code_build_dev_access_policy_arn   = var.code_build_dev_access_policy_arn_value
  code_pipeline_role_name            = var.code_pipeline_role_name_value
  code_pipeline_policy_arn_list      = var.code_code_pipeline_policy_arn_list_value  
  # IAM User
  user_name                          = var.user_name_value
}

module "dynamodb_module" {
  source        = "../modules/dynamodb_module"
  table_name    = var.table_name_value 
}


module "ec2_module" {
  source = "../modules/ec2_module"
  associate_public_ip_address = true
  ami_id                      = "ami-0f9de6e2d2f067fca" # ubuntu
  instance_type               = "t3.medium"
  subnet_id_public            = module.vpc_module.subnet_public_ids[0]
  security_group_id_public    = [module.security_group_module.security_group_public_id]
  key_name                    = "KLTN"
  ec2_tag_name                = "instance-api"
  volume_size                 = "20"
  volume_type                 = "gp2"
  user_data_path = "../script/ec2_api.sh"
}