locals {
  gihub_oidc_already_exists = true
}
resource "aws_iam_openid_connect_provider" "default" {
  count                       = local.gihub_oidc_already_exists ? 0 : 1
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "github_actions_role" {
  name = format("%s-github-actions-role", var.prefix)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = format("arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com", data.aws_caller_identity.current.id)
        }
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : format("repo:%s:*", var.repo_name)
          },
          "ForAllValues:StringEquals" : {
            "token.actions.githubusercontent.com:iss" : "https://token.actions.githubusercontent.com",
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "iam" {
  name = format("%s-github-deployment-policy", var.prefix)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:*Instance*",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:AllocateAddress",
          "ec2:DescribeAddresses",
          "ec2:ReleaseAddress",
          "ec2:CreateTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:CreateInternetGateway",
          "ec2:CreateSubnet",
          "ec2:CreateSecurityGroup",
          "ec2:*",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:*",
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:DeleteParameter",
          "ssm:GetParameters",
          "ssm:ListTagsForResource",
          "ssm:DescribeParameters",
          "ssm:CreateAssociation",
          "ssm:*",
          "logs:CreateLogGroup",
          "logs:*",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:*",
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:ListRolePolicies",
          "iam:*",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:*"
          # Likely to need more or different permissions for successful deployment
          # but you want to try to use least privilege principle where possible
        ],
        "Resource" : "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:ListAllMyBuckets"
        ],
        "Resource": [
          "arn:aws:s3:::tw-iac-demo-taohui-tfstate"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource": [
          "arn:aws:s3:::tw-iac-demo-taohui-tfstate/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "dynamodb:PutItem",
        "Resource": "arn:aws:dynamodb:ap-southeast-2:160071257600:table/tw-iac-demo-tfstate-locks-taohui"
      },
      {
        "Effect": "Allow",
        "Action": "dynamodb:GetItem",
        "Resource": "arn:aws:dynamodb:ap-southeast-2:160071257600:table/tw-iac-demo-tfstate-locks-taohui"
      },
      {
        "Effect": "Allow",
        "Action": "dynamodb:DeleteItem",
        "Resource": "arn:aws:dynamodb:ap-southeast-2:160071257600:table/tw-iac-demo-tfstate-locks-taohui"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "role_policy_attachment" {
  name       = "Policy Attachement"
  policy_arn = aws_iam_policy.iam.arn
  roles      = [aws_iam_role.github_actions_role.name]
}
