region_value  = "us-east-1"

# VPC
vpc_cidr_block_value         = "172.16.0.0/16"
vpc_cidr_block_private_value = ["172.16.1.0/24", "172.16.2.0/24"]
vpc_cidr_block_public_value  = ["172.16.3.0/24", "172.16.4.0/24"]
vpc_subnet_count_value = 2

#route table
destination_cidr_block_private_value = "0.0.0.0/0"
destination_cidr_block_public_value  = "0.0.0.0/0"

#security group private
from_port_in_private_value = 22
to_port_in_private_value   = 22
protocol_in_private_value  = "tcp"

#security group public
ingress_rules_public_value = [
  { from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access from anywhere"
  },
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from anywhere"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from anywhere"
  },
  {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 3000 from anywhere for Client - frontend"
  },
  {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 5000 from anywhere for Server - backend"
  }
]

# S3 bucket
s3_bucket_name_value = "s3_bucket"

# IAM
ec2_role_name_value = "ec2_role"
code_deploy_role_name_value = "codeDeploy_role"
user_name_value = "user"
readonly_policy_arn_value = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
ec2_code_deploy_policy_arn_value = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
code_deploy_policy_arn_value = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
admin_policy_arn_value = "arn:aws:iam::aws:policy/AdministratorAccess"
codebuild_role_name_value = "codeBuild_role"
code_build_dev_access_policy_arn_value = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
code_pipeline_role_name_value = "codePipeline_role"
code_code_pipeline_policy_arn_list_value = [
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess",
  "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess",
  "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess", 
]

#load balancer
load_balancer_type_value = "application" # Application Load Balancer
frontend_port_value = 5001 # Frontend port for the target group
# backend_port_value = 5000 # Backend port for the target group
http_port_value = 80 # HTTP port for the Application Load Balancer

# auto scaling group
ami_id_value = "ami-0f9de6e2d2f067fca" # ubuntu 22.04 ami
instance_type_value = "t3.medium" # t3.medium instance type
key_name_value = "KLTN" # my key pair name
volume_size_value = 20
volume_type_value = "gp2" # General Purpose SSD (gp2) volume type
desired_capacity_value = 2
min_size_value = 2
max_size_value = 4

# route53
route53_zone_name_value = "kltn.mmt.uit"
route53_record_type_value = "A"