locals {
  backend_name          = "networth-tracker-backend"
  image_uri             = "125905898704.dkr.ecr.ap-southeast-1.amazonaws.com/net-worth-tracker-gueh:be-1.0.6"
}

# Provision AWS Lambda function for hosting backend API
resource "aws_iam_role" "networth_backend_exec_role" {
  name = "networth_backend_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "networth_backend_policy" {
  name = "networth_backend_policy"
  path = "/"
  description = "Policy for Lambda to stream logs and pull ECR image"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudWatchAccess"
      Effect    = "Allow"
      Action    = [ "logs:PutLogEvents",
                    "logs:CreateLogStream",
                    "logs:CreateLogGroup" ]
      Resource  = "arn:aws:logs:*:*:*"
    },
    {
      Sid       = "AllowECRPull"
      Effect    = "Allow"
      Action    = [ "ecr:BatchCheckLayerAvailability",
                    "ecr:BatchGetImage",
                    "ecr:GetDownloadUrlForLayer" ]
      Resource  = var.ecr_repository_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "networth_backend_role_attachment" {
  role      = aws_iam_role.networth_backend_exec_role.name
  policy_arn = aws_iam_policy.networth_backend_policy.arn
}

module "lambda_backend" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.backend_name
  description   = "My awesome backend lambda function"

  create_package = false

  package_type = "Image"
  architectures  = [ "x86_64" ]
  image_uri    = local.image_uri

  memory_size = 512
  timeout     = 60

  create_role = false
  lambda_role = aws_iam_role.networth_backend_exec_role.arn

  environment_variables = {
    PORT          = var.backend_port
    JWT_SECRET    = var.backend_jwt_secret
    NODE_ENV      = var.backend_node_env
    DATABASE_URL  = var.backend_database_url
    CLIENT_ORIGIN = var.backend_client_origin
  }

  depends_on = [ aws_iam_role_policy_attachment.networth_backend_role_attachment ]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_lambda_function_url" "backend_url" {
  function_name = module.lambda_backend.lambda_function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = [var.backend_client_origin]
    allow_methods     = ["*"]
    allow_headers     = ["content-type", "authorization"]
    max_age           = 86400
  }
}

# module "cloudfront" {
#   source = "terraform-aws-modules/cloudfront/aws"

#   aliases = []
#   comment             = "CloudFront distribution for frontend SPA (Single Page Application) and backend API"
#   price_class         = "PriceClass_100" # Uses NA/Europe/Asia edge locations (lowest cost)
#   default_root_object = "index.html"


#   origin_access_control = {
#     s3_frontend_oac = {
#       description      = "CloudFront access to S3"
#       origin_type      = "s3"
#       signing_behavior = "always"
#       signing_protocol = "sigv4"
#     }
#   }

#   # Define the 2 Origins: S3 (Frontend) & Lambda Function URL (Backend)
#   origin {
#     domain_name = var.s3_bucket_domain_name
#     origin_access_control = s3_frontend_oac
#   }

#   default_cache_behavior = {
#     target_origin_id       = "something"
#     viewer_protocol_policy = "allow-all"

#     allowed_methods = ["GET", "HEAD", "OPTIONS"]
#     cached_methods  = ["GET", "HEAD"]
#     compress        = true
#     query_string    = true
#   }

#   ordered_cache_behavior = [
#     {
#       path_pattern           = "/static/*"
#       target_origin_id       = "s3"
#       viewer_protocol_policy = "redirect-to-https"

#       allowed_methods = ["GET", "HEAD", "OPTIONS"]
#       cached_methods  = ["GET", "HEAD"]
#       compress        = true
#       query_string    = true
#     }
#   ]

#   viewer_certificate = {
#     acm_certificate_arn = "arn:aws:acm:us-east-1:135367859851:certificate/1032b155-22da-4ae0-9f69-e206f825458b"
#     ssl_support_method  = "sni-only"
#   }
# }