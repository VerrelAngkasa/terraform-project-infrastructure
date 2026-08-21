# Provision AWS ECR repository for storing docker images
resource "aws_iam_user" "github_actions" {
  name = "github-actions-access"

  tags = {
    Terraform   = "true"
  }
}

resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions.name
}

resource "aws_iam_policy" "github_actions_policy" {
  name = "github-actions-policy"
  path = "/"
  description = "Policy for GitHub actions to access ECR repository and update Lambda image tag version"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "AllowECRLogin"
      Effect   = "Allow"
      Action   = "ecr:GetAuthorizationToken"
      Resource = "*"
    },
    {
      Sid      = "AllowLambdaImageUpdate"
      Effect   = "Allow"
      Action   = [ "lambda:UpdateFunctionCode" ]
      Resource = var.lambda_backend_arn
    },
    {
      Sid      = "AllowS3Access"
      Effect   = "Allow"
      Action   = [ "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject",
                   "s3:ListBucket" ]
      Resource = [ "arn:aws:s3:::${local.bucket_name}",
                   "arn:aws:s3:::${local.bucket_name}/*" ]
    }]
  })

  depends_on = [ module.ecr ]

  tags = {
    Terraform   = "true"
  }
}

resource "aws_iam_user_policy_attachment" "github_actions_policy_attachment" {
  user      = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }

    actions = [ "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer" ]
  }

  statement {
    sid = "AllowGitHubActionsAndLambdaRole"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [ aws_iam_user.github_actions.arn,
                      var.networth_backend_lambda_role_arn ]
    }

    actions = [ "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload" ]
  }
}

resource "aws_ecr_repository_policy" "ecr_repository_policy" {
  repository = module.ecr.repository_name
  policy     = data.aws_iam_policy_document.ecr_policy.json
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "net-worth-tracker-gueh"

  create_repository_policy = false
  attach_repository_policy = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 backend images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["be"],
          countType     = "imageCountMoreThan",
          countNumber   = 3
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

# Provision S3 for frontend static web-hosting
locals {
  bucket_name = "networth-tracker-website"
  region      = "ap-southeast-1"
}

data "aws_iam_policy_document" "s3_frontend_bucket_policy" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [ "s3:GetObject" ]
    resources = [ "arn:aws:s3:::${local.bucket_name}/*" ]

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [ var.cloudfront_distribution_arn ]
    }
  }
}

module "s3_frontend_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = local.bucket_name

  force_destroy       = true

  # Bucket policies
  attach_policy                             = true
  policy                                    = data.aws_iam_policy_document.s3_frontend_bucket_policy.json

  # Keep bucket completely private
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  website = {
    index_document = "index.html"
    error_document = "error.html"
    # routing_rules = [{
    #   condition = {
    #     key_prefix_equals = "/"
    #   }
    #   redirect = {
    #     replace_key_prefix_with = "dist/"
    #   }
    # }]
  }

  versioning = {
    status     = false
    mfa_delete = false
  }

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}