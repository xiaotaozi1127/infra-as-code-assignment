locals {
  gihub_oidc_already_exists = true
}
resource "aws_iam_openid_connect_provider" "default" {
  count = local.gihub_oidc_already_exists ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
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
  name = format("%s-github-actions-policy", var.prefix)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups",
          "logs:ListTagsLogGroup",
          "logs:DeleteLogGroup",
          "iam:CreateRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:DeleteRole",
          "iam:CreatePolicy",
          "iam:GetPolicy",
          "iam:DeletePolicy",
          "iam:GetPolicyVersion",
          "iam:AttachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListPolicyVersions",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:DetachRolePolicy",
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::tw-infra-taohui-tfstate"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:CreateBucket"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : "arn:aws:s3:::tw-infra-taohui-website-bucket"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::tw-infra-taohui-website-bucket/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::tw-infra-taohui-tfstate/*",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:CreateTable"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:*"
        ],
        "Resource" : "arn:aws:dynamodb:ap-southeast-2:160071257600:table/tw-infra-taohui-user-info-table",
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem"
        ]
        "Resource" : "arn:aws:dynamodb:ap-southeast-2:160071257600:table/tw-infra-taohui-tfstate-locks"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionConfiguration",
          "lambda:UpdateFunctionCode"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "apigateway:*",
        ],
        "Resource" : [
          "arn:aws:apigateway:ap-southeast-2::/restapis"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "apigateway:*",
        ],
        "Resource" : [
          "arn:aws:apigateway:ap-southeast-2::/restapis/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "apigateway:GET",
          "apigateway:PATCH",
        ],
        "Resource" : [
          "arn:aws:apigateway:ap-southeast-2::/account"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "apigateway:POST"
        ],
        "Resource" : [
          "arn:aws:apigateway:ap-southeast-2::/apikeys",
          "arn:aws:apigateway:ap-southeast-2::/usageplans"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "apigateway:GET",
          "apigateway:PATCH",
          "apigateway:DELETE",
          "apigateway:POST"
        ],
        "Resource" : [
          "arn:aws:apigateway:ap-southeast-2::/apikeys/*",
          "arn:aws:apigateway:ap-southeast-2::/usageplans/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:GetPolicy",
        ],
        "Resource" : [
          "arn:aws:lambda:ap-southeast-2:160071257600:function:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "role_policy_attachment" {
  name       = "Policy Attachment"
  policy_arn = aws_iam_policy.iam.arn
  roles      = [aws_iam_role.github_actions_role.name]
}
