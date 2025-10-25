# create role for EC2 instances
resource "aws_iam_role" "ec2_role" {
    name = var.ec2_role_name
    description = "Role for EC2 instances to access S3 and code Deploy"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "ec2.amazonaws.com"
                    ]
                }
            }
        ]
    })
}
  
# create role for code deploy
resource "aws_iam_policy_attachment" "ec2_role_policy_attachment_s3_readonly" {
    name       = "ec2_role_policy_attachment_s3_readonly"
    roles      = [aws_iam_role.ec2_role.name]
    policy_arn = var.readonly_policy_arn
}

resource "aws_iam_policy_attachment" "ec2_role_policy_attachment_codedeploy" {
    name       = "ec2_role_policy_attachment_codedeploy"
    roles      = [aws_iam_role.ec2_role.name]
    policy_arn = var.ec2_code_deploy_policy_arn
}

# ============================================================
# Allow EC2 to write logs to DynamoDB (IDS logs)
# ============================================================
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "ec2_dynamodb_access" {
  name = "EC2DynamoDBAccess"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${var.table_name_value}"
      }
    ]
  })
}



resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "codeDeploy_role" {
    name = var.code_deploy_role_name
    description = "Role for CodeDeploy"
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
    "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "codedeploy.amazonaws.com"
                    ]
                },
                "Action": [
                    "sts:AssumeRole"
                ]
            }
        ]
    })
  
}

resource "aws_iam_policy_attachment" "codeDeploy_role_policy_attachment_codedeploy" {
    name       = "codeDeploy_role_policy_attachment_codedeploy"
    roles      = [aws_iam_role.codeDeploy_role.name]
    policy_arn = var.code_deploy_policy_arn
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name = "codedeploy-policy"
  role = aws_iam_role.codeDeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:*",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListObjects",
          "ec2:DescribeInstances",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTargetGroups",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "codedeploy:PollHostCommand",
          "codedeploy:PutLifecycleEventHookExecutionStatus",
          "codedeploy:UpdateDeploymentStatus",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig"
        ]
        Resource = "*"
      }
    ]
  })
}

# create a user
resource "aws_iam_user" "user" {
    name = var.user_name
}
resource "aws_iam_user_policy_attachment" "user_policy_attachment_admin" {
    user       = aws_iam_user.user.name
    policy_arn = var.admin_policy_arn
}

# create role for code build
resource "aws_iam_role" "codeBuild_role" {
    name = var.codebuild_role_name
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "codebuild.amazonaws.com"
                    ]
                }
            }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "codeBuild_role_policy_attachment" {
    role       = aws_iam_role.codeBuild_role.name
    policy_arn = var.code_build_dev_access_policy_arn
}

resource "aws_iam_role_policy" "codebuild_cloudwatch_policy" {
  name = "CodeBuildCloudWatchPolicy"
  role = aws_iam_role.codeBuild_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_S3_policy" {
  name = "CodeBuildS3Policy"
  role = aws_iam_role.codeBuild_role.name
  policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:PutObject"
                ],
                Resource = "*"
                    
            },
            {
                Effect = "Allow"
                Action = [
                    "s3:ListBucket"
                ]
                Resource = "*"
            }
        ]
    })
}

# codepipeline role
resource "aws_iam_role" "codePipeline_role" {
    name = var.code_pipeline_role_name
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "sts:AssumeRole"
                ],
                Principal = {
                    Service = [
                        "codepipeline.amazonaws.com"
                    ]
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "codePipeline_role_policy_attachment" {
    role       = aws_iam_role.codePipeline_role.name
    for_each   = toset(var.code_pipeline_policy_arn_list)
    policy_arn = each.value
}