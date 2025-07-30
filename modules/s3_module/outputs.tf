output "s3_bucket_id" {
  description = "The name of the S3 bucket created by the module."
  value       = aws_s3_bucket.s3_bucket.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket created by the module."
  value       = aws_s3_bucket.s3_bucket.arn
  
}

output "s3_bucket_bucket" {
  description = "The bucket name of the S3 bucket created by the module."
  value       = aws_s3_bucket.s3_bucket.bucket
  
}
