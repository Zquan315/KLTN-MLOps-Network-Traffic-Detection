# variables for alb
variable "load_balancer_type_value" {
  description = "Type of the load balancer (e.g., application, network)"
  type        = string
}

variable "http_port_value" {
  description = "HTTP port for the Application Load Balancer"
  type        = number
}

# variables for autoscaling group
variable "ami_id_value" {
  description = "AMI ID for the EC2 instances"
  type        = string
}
variable "instance_type_value" {
  description = "Instance type for the EC2 instances"
  type        = string
}
variable "key_name_value" {
  description = "Key pair name for SSH access to the EC2 instances"
  type        = string
}

variable "volume_size_value" {
  description = "Size of the EBS volume in GB"
  type        = number
}
variable "volume_type_value" {
  description = "Type of the EBS volume (e.g., gp2, io1)"
  type        = string
}

variable "user_data_path_value" {
  description = "path for script .sh"
  type        = string
}

variable "desired_capacity_value" {
  description = "Desired capacity for the Auto Scaling group"
  type        = number
}
variable "min_size_value" {
  description = "Minimum size for the Auto Scaling group"
  type        = number
}
variable "max_size_value" {
  description = "Maximum size for the Auto Scaling group"
  type        = number
}

# variables for route53
variable "route53_zone_name_value" {
  description = "The name of the Route 53 hosted zone"
  type        = string
}
variable "route53_record_type_value" {
  description = "The type of the Route 53 record (e.g., A, CNAME)"
  type        = string
}