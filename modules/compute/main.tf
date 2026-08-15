locals {
  backend_name          = "networth-tracker-backend"
  image_uri             = "125905898704.dkr.ecr.ap-southeast-1.amazonaws.com/net-worth-tracker-gueh:be-1.0.6"

  backend_port          = var.backend_port
  backend_jwt_secret    = var.backend_jwt_secret
  backend_node_env      = var.backend_node_env
  backend_database_url  = var.backend_database_url
  backend_client_origin = var.backend_client_origin
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
    PORT          = local.backend_port
    JWT_SECRET    = local.backend_jwt_secret
    NODE_ENV      = local.backend_node_env
    DATABASE_URL  = local.backend_database_url
    CLIENT_ORIGIN = local.backend_client_origin
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
    allow_origins     = [local.backend_client_origin]
    allow_methods     = ["*"]
    allow_headers     = ["content-type", "authorization"]
    max_age           = 86400
  }
}