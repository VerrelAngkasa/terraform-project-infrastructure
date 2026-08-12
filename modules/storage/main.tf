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
      Sid       = "AllowECRLogin"
      Effect    = "Allow"
      Action    = [ "ecr:GetAuthorizationToken" ]
      Resource  = "*"
    }, 
    {
      Sid       = "AllowECRAccess"
      Effect    = "Allow"
      Action    = [ "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CompleteLayerUpload",
                    "ecr:PutImage",
                    "ecr:BatchGetImage",
                    "ecr:BatchCheckLayerAvailability" ]
      Resource  = module.ecr.repository_arn
    },
    {
      Sid       = "AllowLambdaImageUpdate"
      Effect    = "Allow"
      Action    = [ "lambda:UpdateFunctionCode" ]
      Resource  = var.lambda_backend_arn
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

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "net-worth-tracker-gueh"

  repository_read_write_access_arns = [ aws_iam_user.github_actions.arn ]
  repository_read_access_arns       = [ var.networth_backend_exec_role ]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 backend images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["be"],
          countType     = "imageCountMoreThan",
          countNumber   = 5
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep last 5 frontend images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["fe"],
          countType     = "imageCountMoreThan",
          countNumber   = 5
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
# locals {
#   frontend_bucket_name = "networth-tracker-frontend"
# }

# resource "aws_s3_bucket_website_configuration" "example" {
#   bucket = local.frontend_bucket_name

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "error.html"
#   }

#   routing_rule {
#     condition {
#       key_prefix_equals = "docs/"
#     }
#     redirect {
#       replace_key_prefix_with = "documents/"
#     }
#   }
  
#   tags = {
#     Terraform   = "true"
#     Environment = "prod"
#   }
# }

