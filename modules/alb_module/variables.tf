variable "load_balancer_type" {
  description = "NameType of the ALB"
  type        = string
  default = "application"
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
}
variable "alb_security_group_id" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the ALB and target group will be created"
  type        = string
}

variable "http_port" {
  description = "Port for the HTTP listener"
  type        = number
  default     = 80
}


# Mỗi route: tạo 1 target group + 1 listener rule
variable "routes" {
  description = "Danh sách rule định tuyến theo path → port đích trên EC2"
  type = list(object({
    name           = string
    port           = number
    path_patterns  = list(string)       # ví dụ ["/metrics"] hoặc ["/logs","/logs/*"]
    health_path    = string             # ví dụ "/"
    matcher        = optional(string)   # ví dụ "200" hoặc "200-399"
  }))
}

# Tên route dùng làm default_action cho path "/"
variable "default_route_name" {
  type        = string
  description = "Tên route làm default (ứng với path /)"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener"
}

