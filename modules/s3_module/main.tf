resource "aws_s3_bucket" "s3_bucket" {
    bucket = var.bucket_name_value
    force_destroy = true
    tags = {
        Name = var.bucket_name_value
    }
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
    bucket = aws_s3_bucket.s3_bucket.id
    versioning_configuration {
        status = var.versioning_enabled_value ? "Enabled" : "Suspended"
    }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_block" {
    bucket = aws_s3_bucket.s3_bucket.id

    block_public_acls       = var.block_public_acls
    block_public_policy     = var.block_public_policy
    ignore_public_acls      = var.ignore_public_acls
    restrict_public_buckets = var.restrict_public_buckets
  
}