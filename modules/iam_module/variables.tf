variable "ec2_role_name" {
  description = "Name of the IAM role for EC2 instances"
  type        = string
  default     = "arf-ids-ec2-role"
}

variable "code_deploy_role_name" {
  description = "Name of the IAM role for CodeDeploy"
  type        = string
  default     = "arf-ids-codedeploy-role"
}

variable "readonly_policy_arn" {
  description = "ARN of the read-only policy for S3"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

variable "ec2_code_deploy_policy_arn" {
  description = "ARN of the CodeDeploy policy for EC2 instances"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

variable "code_deploy_policy_arn" {
  description = "ARN of the CodeDeploy policy for CodeDeploy role"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

variable "user_name" {
  description = "Name of the IAM user"
  type        = string
  default     = "arf-ids-admin"
}

variable "admin_policy_arn" {
  description = "ARN of the admin policy for IAM user"
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "codebuild_role_name" {
  description = "Name of the IAM role for CodeBuild"
  type        = string
  default     = "arf-ids-codebuild-role"
}

variable "code_build_dev_access_policy_arn" {
  description = "ARN of the CodeBuild developer access policy"
  type        = string
  default     = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

variable "code_pipeline_role_name" {
  description = "Name of the IAM role for CodePipeline"
  type        = string
  default     = "arf-ids-codepipeline-role"
}

variable "code_pipeline_policy_arn_list" {
  description = "List of ARN policies for CodePipeline role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"]
}

variable "table_name_value" {
  description = "DynamoDB table name for IDS logs"
  type        = string
  default     = "ids_log_system"
}

variable "sqs_queue_arn" {
  description = "ARN của SQS queue dùng cho cảnh báo"
  type        = string
  default     = null
}

variable "count_value" {
  description = "Số lượng để tạo policy SQS (0 hoặc 1)"
  type        = number
  default     = 1
}
