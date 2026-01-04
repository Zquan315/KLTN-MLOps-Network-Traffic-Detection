terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-99999" 
    key            = "create-infrastructure/terraform.tfstate"
    region         = "us-east-1" 
  }
}

# create VPC and subnets
module "vpc_module" {
  source = "../modules/vpc_module"
  #VPC
  cidr_block_value         = var.vpc_cidr_block_value
  cidr_block_private_value = var.vpc_cidr_block_private_value
  cidr_block_public_value  = var.vpc_cidr_block_public_value
  subnet_count_value       = var.vpc_subnet_count_value
}

# Create Nat Gateway
module "nat_gateway_module" {
  source = "../modules/nat_gateway_module"
  region_network_border_group = var.region_value
  # NAT Gateway
  nat_gateway_subnet_id       = module.vpc_module.subnet_public_ids[0]
}

# create route table
module "route_table_module" {
  source = "../modules/route_table_module"

  # Route Table
  vpc_id_value = module.vpc_module.vpc_id

  # Route Table Private
  destination_cidr_block_private = var.destination_cidr_block_private_value
  gateway_id_private             = module.nat_gateway_module.nat_gateway_id
  subnet_id_private              = [module.vpc_module.subnet_private_ids[0], 
                                    module.vpc_module.subnet_private_ids[1],
                                    module.vpc_module.subnet_private_ids[2],
                                    module.vpc_module.subnet_private_ids[3]]

  # Route Table Public
  destination_cidr_block_public  = var.destination_cidr_block_public_value
  gateway_id_public              = module.vpc_module.internet_gateway_id
  subnet_id_public               = [module.vpc_module.subnet_public_ids[0], 
                                   module.vpc_module.subnet_public_ids[1],
                                   module.vpc_module.subnet_public_ids[2],
                                   module.vpc_module.subnet_public_ids[3]]
}

# Create Security Groups
module "security_group_module" {
  source = "../modules/security_group_module"
  vpc_id = module.vpc_module.vpc_id
  # Security Group Private ingress

  from_port_in_private = var.from_port_in_private_value
  to_port_in_private   = var.to_port_in_private_value
  protocol_in_private  = var.protocol_in_private_value

  # Security Group Public ingress
  ingress_rules_public = var.ingress_rules_public_value

}

# Create EFS File System for Monitoring (Prometheus, Grafana, Alertmanager)
module "efs_module" {
  source = "../modules/efs_module"
  
  efs_name       = var.efs_name_value
  creation_token = var.efs_token_value
  encrypted      = true
  
  # Use general purpose performance mode for monitoring workloads
  performance_mode = var.efs_performance_mode_value
  throughput_mode  = var.efs_throughput_mode_value
  
  # Create mount targets in public subnets where monitoring instances run
  subnet_ids = [
    module.vpc_module.subnet_public_ids[1],
    module.vpc_module.subnet_public_ids[2]
  ]
  
  # Use EFS security group
  security_group_ids = [module.security_group_module.sg_efs_id]
  
  tags = {
    Name        = "monitoring-efs"
    Environment = "production"
    Purpose     = "monitoring-data-persistence"
  }
}

# Create S3 bucket
module "s3_module" {
  source = "../modules/s3_module"
  bucket_name_value         = var.s3_bucket_name_value
}


# Create IAM 
module "iam_module" {
  source                             = "../modules/iam_module"
  ec2_role_name                      = var.ec2_role_name_value
  code_deploy_role_name              = var.code_deploy_role_name_value
  readonly_policy_arn                = var.readonly_policy_arn_value
  ec2_code_deploy_policy_arn         = var.ec2_code_deploy_policy_arn_value
  code_deploy_policy_arn             = var.code_deploy_policy_arn_value
  admin_policy_arn                   = var.admin_policy_arn_value
  codebuild_role_name                = var.codebuild_role_name_value
  code_build_dev_access_policy_arn   = var.code_build_dev_access_policy_arn_value
  code_pipeline_role_name            = var.code_pipeline_role_name_value
  code_pipeline_policy_arn_list      = var.code_code_pipeline_policy_arn_list_value
  # IAM User
  user_name                          = var.user_name_value
  table_name_value                   = "ids_log_system"
}

module "dynamodb_module" {
  source        = "../modules/dynamodb_module"
  table_name    = var.table_name_value 
}


# ===========================================
# S3 BUCKET FOR TRAINING DATA (base.csv + drift data)
# ===========================================
module "s3_training_data_bucket" {
  source = "../modules/s3_module"

  bucket_name_value        = "qmuit-training-data-store"
  versioning_enabled_value = true

  # Block all public access
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}


# ===========================================
# S3 bucket dành cho API model (ARF IDS)
# ===========================================
module "s3_api_model_bucket" {
  source = "../modules/s3_module"

  bucket_name_value         = "qmuit-mlflow-artifacts-store"
  versioning_enabled_value  = true

  # Public access block
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
}



# ===========================================
# IAM policy cho phép đọc model từ S3 bucket
# ===========================================
resource "aws_iam_policy" "arf_s3_model_access" {
  name = "arf-s3-model-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::qmuit-mlflow-artifacts-store",
          "arn:aws:s3:::qmuit-mlflow-artifacts-store/*",
          "arn:aws:s3:::arf-ids-model-bucket",
          "arn:aws:s3:::arf-ids-model-bucket/*"
        ]
      }
    ]
  })
}


# ============================================================
# EKS CLUSTER
# ============================================================

locals {
  vpc_id             = module.vpc_module.vpc_id
  subnet_private_ids = module.vpc_module.subnet_private_ids
  subnet_public_ids  = module.vpc_module.subnet_public_ids
  sg_public_id       = module.security_group_module.security_group_public_id

  eks_cluster_role_arn            = module.iam_module.eks_cluster_role_arn
  eks_node_role_arn               = module.iam_module.eks_node_role_arn
  arf_s3_model_access_policy_arn  = aws_iam_policy.arf_s3_model_access.arn
  api_model_bucket_name           = module.s3_api_model_bucket.s3_bucket_bucket
  training_data_bucket_name = module.s3_training_data_bucket.s3_bucket_bucket
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                   = var.eks_cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  vpc_id     = local.vpc_id
  subnet_ids = concat(local.subnet_private_ids, local.subnet_public_ids)
  control_plane_subnet_ids = local.subnet_private_ids

  create_iam_role = false
  iam_role_arn    = local.eks_cluster_role_arn
  enable_irsa = true
  enable_cluster_creator_admin_permissions = false


  eks_managed_node_groups = {
    api-nodes = {
      name           = "api"
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      force_update_version = true
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      subnet_ids = local.subnet_private_ids
      create_iam_role = false
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

resource "aws_iam_policy" "ids_training_data_access" {
  name = "ids-training-data-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::qmuit-training-data-store",
          "arn:aws:s3:::qmuit-training-data-store/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_training_data_access" {
  role       = basename(module.eks.eks_managed_node_groups["api-nodes"].iam_role_arn)
  policy_arn = aws_iam_policy.ids_training_data_access.arn

  depends_on = [module.eks]
}

resource "aws_iam_policy" "ids_dynamodb_access" {
  name = "ids-dynamodb-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:947632013035:table/ids_log_system"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_dynamodb_access" {
  role       = basename(module.eks.eks_managed_node_groups["api-nodes"].iam_role_arn)
  policy_arn = aws_iam_policy.ids_dynamodb_access.arn

  depends_on = [module.eks]
}

locals {
  oidc_provider_url = replace(module.eks.oidc_provider, "https://", "")
}

resource "aws_iam_role" "ebs_csi_irsa_role" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_irsa_role_attachment" {
  role       = aws_iam_role.ebs_csi_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_irsa_role.arn

  depends_on = [module.eks]
}

