variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}
variable "s3_bucket_name_mlops_value" {
  description = "Tên bucket S3 dùng cho lưu trữ MLOps artifacts"
  type        = string
}
