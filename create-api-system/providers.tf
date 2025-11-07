terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================
# Kubernetes Provider – DÙNG exec
# ==============================
provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.main.name,
      "--region",
      var.aws_region
    ]
  }
}

# ==============================
# Data source
# ==============================
data "aws_eks_cluster" "main" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}