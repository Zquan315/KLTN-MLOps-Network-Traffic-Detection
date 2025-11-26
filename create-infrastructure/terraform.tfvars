region_value  = "us-east-1"

# VPC
vpc_cidr_block_value         = "172.16.0.0/16"
vpc_cidr_block_private_value = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24", "172.16.4.0/24"]
vpc_cidr_block_public_value  = ["172.16.5.0/24", "172.16.6.0/24", "172.16.7.0/24", "172.16.8.0/24"]
vpc_subnet_count_value = 4

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
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 9100 from anywhere for grafana"
  },
  {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 9090 from anywhere for prometheus"
  },
  {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 5001 from anywhere for ids"
  },
  {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 5000 from anywhere for mlflow"
  },
  {
    from_port   = 5500
    to_port     = 5500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 5500 from anywhere for honey pot"
  },
  {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 8000 from anywhere for predict API"
  },
  {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 8080 from anywhere for log - frontend"
  },
  {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 8081 from anywhere for log - backend"
  },
  {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Access to port 8081 from anywhere for log - database"
  }
]

# S3 bucket
s3_bucket_name_value = "s3-bucket-qm"

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
  "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess",
  "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess", 
]


# dynamodb
table_name_value = "ids_log_system"

# EKS
eks_cluster_name = "arf-ids-cluster"