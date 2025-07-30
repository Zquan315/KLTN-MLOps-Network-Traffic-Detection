resource "aws_codepipeline" "codePipeline" {
  name     = var.pipeline_name
  role_arn = var.role_arn
  execution_mode = "SUPERSEDED"

  artifact_store {
    location = var.s3_bucket
    type     = "S3"

    # encryption_key {
    #   id   = var.kms_key_arn
    #   type = "KMS"
    # }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]  # default CodePipeline output artifact

      configuration = {
        Owner = var.github_owner
        Repo  = var.github_repo
        Branch = var.github_branch
        OAuthToken = var.github_oauth_token
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
      configuration = {
        ProjectName = var.build_project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ApplicationName     = var.application_name
        DeploymentGroupName = var.deployment_group_name
      }
    }
  }
}
