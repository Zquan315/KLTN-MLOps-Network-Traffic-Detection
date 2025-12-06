terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-99999"
    key    = "create-api-system/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-99999"
    key    = "create-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  cluster_name     = data.terraform_remote_state.infra.outputs.eks_cluster_name
  oidc_provider_arn = data.terraform_remote_state.infra.outputs.eks_oidc_provider_arn
}