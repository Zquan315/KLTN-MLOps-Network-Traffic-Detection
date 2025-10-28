variable "ec2_role_name" {
  description = "Name of the IAM role for EC2 instances"
  type        = string
}

variable "code_deploy_role_name" {
  description = "Name of the IAM role for CodeDeploy"
  type        = string
  
}

variable "user_name" {
  description = "Name of the IAM user"
  type        = string
  
}

variable "readonly_policy_arn" {
  description = "ARN of the read-only policy for S3"
  type        = string
}
variable "ec2_code_deploy_policy_arn" {
  description = "ARN of the CodeDeploy policy for EC2 instances"
  type        = string
}
variable "code_deploy_policy_arn" {
  description = "ARN of the CodeDeploy policy for CodeDeploy role"
  type        = string
}
variable "admin_policy_arn" {
  description = "ARN of the admin policy for IAM user"
  type        = string
  
}

variable "codebuild_role_name" {
  description = "Name of the IAM role for CodeBuild"
  type        = string
}
variable "code_build_dev_access_policy_arn" {
  description = "ARN of the CodeBuild developer access policy"
  type        = string
  
}

variable "code_pipeline_role_name" {
  description = "Name of the IAM role for CodePipeline"
  type        = string 
}
variable "code_pipeline_policy_arn_list" {
  description = "ARN of the CodePipeline policy for the role"
  type        = list(string)
}

variable "table_name_value" {
  description = "DynamoDB table name for IDS logs"
  type        = string
}

# sqs

variable "sqs_queue_arn" {
  description = "ARN của SQS queue dùng cho cảnh báo"
  type        = string
}

variable "count_value" {
  description = "Số lượng để tạo policy SQS (0 hoặc 1)"
  type        = number
  default     = 1
}