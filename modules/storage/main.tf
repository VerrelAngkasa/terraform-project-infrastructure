# Provision AWS ECR repository for storing docker images
resource "aws_iam_user" "github_actions" {
  name = "github-actions-access"

  tags = {
    Terraform   = "true"
  }
}

# resource "aws_iam_access_key" "github_actions_key" {
#   user = aws_iam_user.github_actions.name
# }

resource "aws_iam_policy" "github_actions_policy" {
  name = "github-actions-policy"
  path = "/"
  description = "Policy for github actions to access ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowECRAccess"
      Effect    = "Allow"
      Action    = [ "ecr:*" ]
      Resource  = module.ecr.repository_arn
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

  repository_name = "mynetworth-tracker"

  repository_read_write_access_arns = [resource.aws_iam_user.github_actions.arn]
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
# module "s3_bucket" {
#   source = "terraform-aws-modules/s3-bucket/aws"

#   bucket = "networth-tracker-frontend"
#   acl    = "private"

#   control_object_ownership = true
#   object_ownership         = "ObjectWriter"

#   versioning = {
#     enabled = true
#   }

#   website = {
#     index_document = ""
#     error_document = ""
#     routing_rules = [{}]
#   }

#   tags = {
#     Terraform = "true"
#   }
# }

