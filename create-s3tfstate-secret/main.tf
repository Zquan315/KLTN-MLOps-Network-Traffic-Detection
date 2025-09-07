resource "aws_s3_bucket" "terraform-state-bucket" {
    bucket = "terraform-state-bucket-qm"
    force_destroy = true
    tags = {
        Name = "terraform-state-bucket-qm"
    }
}


resource "aws_s3_bucket_versioning" "terraform-state-bucket-versioning" {
    bucket = aws_s3_bucket.terraform-state-bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "bucket-public-access-block" {
    bucket = aws_s3_bucket.terraform-state-bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  
}


# resource "aws_secretsmanager_secret" "github_OAuthToken" {
#   name = "github_oauth_token"

# }

# resource "aws_secretsmanager_secret_version" "github_OAuthToken_value" {
#   secret_id     = aws_secretsmanager_secret.github_OAuthToken.id
#   secret_string = var.github_oauth_token_value 
# }
