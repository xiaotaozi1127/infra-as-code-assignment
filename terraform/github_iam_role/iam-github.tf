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
  #checkov:skip=CKV_AWS_289:Ensure IAM policies does not allow permissions management / resource exposure without constraints
  #checkov:skip=CKV_AWS_355:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
  #checkov:skip=CKV_AWS_290:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_286:Ensure IAM policies does not allow privilege escalation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:ListTagsLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:AssociateKmsKey",
        ],
        "Resource" : "arn:aws:logs:ap-southeast-2:160071257600:log-group:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:PassRole",
          "iam:DeleteRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListInstanceProfilesForRole",
        ],
        "Resource" : "arn:aws:iam::160071257600:role/tw-infra-taohui*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreatePolicy",
          "iam:GetPolicy",
          "iam:CreatePolicyVersion",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:DeletePolicy",
        ],
        "Resource" : "arn:aws:iam::160071257600:policy/tw-infra-taohui*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets",
          "s3:ListBucket"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:CreateBucket",
          "S3:GetBucketPolicy",
          "s3:GetBucketWebsite",
          "s3:GetBucketVersioning",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetLifecycleConfiguration",
          "S3:GetBucketReplication",
          "s3:GetReplicationConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketLogging",
          "s3:GetBucketTagging",
          "s3:GetObjectTagging",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::tw-infra-taohui-website-bucket",
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
          "dynamodb:CreateTable",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
        ],
        "Resource" : [
            "arn:aws:dynamodb:ap-southeast-2:160071257600:table/tw-infra-taohui-user-info-table"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DescribeTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DescribeContinuousBackups",
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
          "lambda:UpdateFunctionCode",
          "lambda:PutFunctionConcurrency"
        ],
        "Resource" : [
          "arn:aws:lambda:ap-southeast-2:160071257600:function:tw-infra-taohui*"
        ]
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
