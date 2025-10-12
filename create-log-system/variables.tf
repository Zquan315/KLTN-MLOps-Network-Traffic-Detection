# variables loadbalancer and asg
variable "load_balancer_type_value" {
  description = "Type of load balancer (application or network)"
  type        = string
}

variable "http_port_value" {
  description = "HTTP port for the load balancer"
  type        = number
}

variable "ami_id_value" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "instance_type_value" {
  description = "Instance type for the EC2 instances"
  type        = string
}

variable "key_name_value" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "volume_size_value" {
  description = "Size of the EBS volume in GB"
  type        = number
}

variable "volume_type_value" {
  description = "Type of the EBS volume (e.g., gp2, gp3, io1)"
  type        = string
}

variable "desired_capacity_value" {
  description = "Desired number of instances in the Auto Scaling group"
  type        = number
}

variable "min_size_value" {
  description = "Minimum number of instances in the Auto Scaling group"
  type        = number
}

variable "max_size_value" {
  description = "Maximum number of instances in the Auto Scaling group"
  type        = number
}

variable "user_data_path_value" {
  description = "Path to the user data script for EC2 instances"
  type        = string
}

# variables for route53
variable "route53_zone_name_value" {
  description = "Route 53 hosted zone name"
  type        = string
}
variable "route53_record_type_value" {
  description = "Type of DNS record (e.g., A, CNAME)"
  type        = string
}

# variables for codeDeploy
variable "code_deploy_app_name_value" {
  description = "Name of the CodeDeploy application"
  type        = string
}
variable "compute_platform_value" {
  description = "Compute platform for the CodeDeploy application (e.g., 'EC2/on-premises', 'Lambda', 'ECS')"
  type        = string
}
variable "deployment_group_name_value" {
  description = "Name of the CodeDeploy deployment group"
  type        = string
}
variable "deployment_option_value" {
  description = "Deployment option for CodeDeploy (e.g., 'WITH_TRAFFIC_CONTROL', 'WITHOUT_TRAFFIC_CONTROL')"
  type        = string
}

# variables for codeBuild
variable "code_build_project_name_value" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "github_repo_value" {
  description = "name of repo on github"
  type = string
}

# variables for codePipeline
variable "code_pipeline_name_value" {
  description = "Name of the CodePipeline"
  type        = string
}


variable "github_owner_value" {
  description = "User of github"
  type = string
}