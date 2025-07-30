variable "pipeline_name" {
  description = "The name of the CodePipeline"
  type        = string
}

variable "role_arn" {
  description = "The ARN of the IAM role for CodePipeline"
  type        = string
}

variable "s3_bucket" {
  description = "The name of the S3 bucket to store pipeline artifacts"
  type        = string
}

# variable "kms_key_arn" {
#   description = "The ARN of the KMS key for artifact encryption"
#   type        = string
# }


variable "build_project_name" {
  description = "The name of the AWS CodeBuild project"
  type        = string
}

variable "application_name" {
  description = "The name of the AWS CodeDeploy application"
  type        = string
}

variable "deployment_group_name" {
  description = "The name of the AWS CodeDeploy deployment group"
  type        = string
}

variable "github_owner" {
  description = "github owner"
  type = string
}

variable "github_branch" {
  description = "branch of repo is used"
  type = string
  default = "main"
}

variable "github_repo" {
  description = "name of repo"
  type = string
}

variable "github_oauth_token" {
  description = "oauth token of github"
  type = string
}
