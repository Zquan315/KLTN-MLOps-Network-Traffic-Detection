
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
      ConnectionArn    = "arn:aws:codeconnections:us-east-1:897722710732:connection/307a5f14-e6a2-43ef-8704-ca2954559dc7"
      FullRepositoryId = "Zquan315/KLTN-Log-system-app"
      BranchName       = "main"
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
