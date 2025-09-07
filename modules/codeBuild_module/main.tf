resource "aws_codebuild_project" "codebuild-project" {
  name         = var.project_name
  service_role = var.service_role_arn

  artifacts {
    type      = "S3"
    location  = var.s3_bucket
    packaging = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL" # 4GB RAM, 2 vCPUs, 64GB disk
    image                       = "aws/codebuild/standard:7.0" # ubuntu latest managed image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
  source_version = "main"

  logs_config {
    cloudwatch_logs {
      group_name  = ""
      stream_name = ""
    }
  }

}
