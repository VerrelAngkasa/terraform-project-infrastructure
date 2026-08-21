locals {
  backend_name          = "networth-tracker-backend"
  image_uri             = "125905898704.dkr.ecr.ap-southeast-1.amazonaws.com/net-worth-tracker-gueh:be-1.0.6"
  lambda_domain_name    = replace(replace(aws_lambda_function_url.backend_url.function_url, "https://", ""), "/", "")
}

# Provision AWS Lambda function for hosting backend API
resource "aws_iam_role" "networth_backend_lambda_role" {
  name = "networth_backend_lambda_role"

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
      Sid      = "AllowCloudWatchAccess"
      Effect   = "Allow"
      Action   = [ "logs:PutLogEvents",
                   "logs:CreateLogStream",
                   "logs:CreateLogGroup" ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "networth_backend_role_attachment" {
  role      = aws_iam_role.networth_backend_lambda_role.name
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
  lambda_role = aws_iam_role.networth_backend_lambda_role.arn

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

# Provision CloudFront for route frontend and backend
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name = "s3_frontend_oac"
  description = "OAC for CloudFront to access S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"

  comment             = "CloudFront distribution for frontend SPA (Single Page Application) and backend API"
  price_class         = "PriceClass_100" # Uses NA/Europe/Asia edge locations (lowest cost)
  default_root_object = "index.html"

  # Define the 2 Origins: S3 (Frontend) & Lambda Function URL (Backend)
  origin = {
    s3_frontend = {
      domain_name = var.s3_bucket_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    }

    lambda_backend = {
      domain_name = local.lambda_domain_name
      custom_origin_config = {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols = ["TLSv1.2"]
      }
    }
  }

  # Default Behavior: /* -> Routes to S3 Frontend
  default_cache_behavior = {
    target_origin_id       = "s3_frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress       = true
  }

  # Ordered Behavior: /api/* -> Routes to Lambda Function URL
  ordered_cache_behavior = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "lambda_backend"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]
      cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
      compress        = true
    }
  ]

  # SPA Routing Rewrites (React/Vue/Vite Router support)
  custom_error_response = [
     {
      error_code = 403
      response_code = 200
      response_page_path = "/error.html"
      error_caching_min_ttl = 0
    },
    {
      error_code = 404
      response_code = 200
      response_page_path = "/error.html"
      error_caching_min_ttl = 0
    }
  ]

  viewer_certificate = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2025"
  }

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}