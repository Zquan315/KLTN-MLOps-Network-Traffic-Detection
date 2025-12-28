variable "load_balancer_type_value" {
  description = "Type of the load balancer"
  type        = string
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
  description = "Type of the EBS volume"
  type        = string
}

variable "desired_capacity_value" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
}

variable "min_size_value" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "max_size_value" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "user_data_path_value" {
  description = "Path to the user data script for EC2 instances"
  type        = string
}

variable "function_name_value" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_source_file_path_value" {
  description = "Path to the Lambda function source code"
  type        = string
}

variable "sender_email_value" {
  description = "Sender email address for alerts"
  type        = string
}
variable "to_email_value" {
  description = "Recipient email address for alerts"
  type        = string
}