terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-9999"
    key    = "create-api-system/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-9999"
    key    = "create-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}


locals {
  vpc_id             = data.terraform_remote_state.infra.outputs.vpc_id
  subnet_private_ids = data.terraform_remote_state.infra.outputs.subnet_private_ids
  subnet_public_ids  = data.terraform_remote_state.infra.outputs.subnet_public_ids
  sg_public_id       = data.terraform_remote_state.infra.outputs.security_group_public_id

  eks_cluster_role_arn          = data.terraform_remote_state.infra.outputs.eks_cluster_role_arn
  eks_node_role_arn             = data.terraform_remote_state.infra.outputs.eks_node_role_arn
  arf_s3_model_access_policy_arn = data.terraform_remote_state.infra.outputs.arf_s3_model_access_policy_arn
  api_model_bucket_name         = data.terraform_remote_state.infra.outputs.api_model_bucket_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.13.1"

  cluster_name                   = "arf-ids-cluster"
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_private_ids

  # Dùng IAM roles từ infra
  create_iam_role = false
  iam_role_arn    = local.eks_cluster_role_arn

  eks_managed_node_groups = {
    api-nodes = {
      name           = "api"
      desired_size   = 1
      min_size       = 1
      max_size       = 3
      instance_types = ["t2.medium"]
      capacity_type  = "ON_DEMAND"
      iam_role_arn   = local.eks_node_role_arn
    }
  }

  tags = {
    Project     = "arf-ids"
    Env         = "prod"
    S3ModelBucket = local.api_model_bucket_name
  }
}


resource "aws_iam_role_policy_attachment" "eks_node_s3_model_access" {
  role       = basename(module.eks.eks_managed_node_groups["api-nodes"].iam_role_arn)
  policy_arn = local.arf_s3_model_access_policy_arn
  depends_on = [module.eks]
}

data "aws_caller_identity" "current" {}

locals {
  eks_admins = {
    root   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    minhbq = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/minhbq"
    quantc = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/quantc"
  }
}

resource "aws_eks_access_entry" "admins" {
  for_each      = local.eks_admins
  cluster_name  = module.eks.cluster_name
  principal_arn = each.value
  type          = "STANDARD"
  depends_on    = [module.eks]
}

resource "aws_eks_access_policy_association" "admins" {
  for_each      = local.eks_admins
  cluster_name  = module.eks.cluster_name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    module.eks,
    aws_eks_access_entry.admins
  ]
}
