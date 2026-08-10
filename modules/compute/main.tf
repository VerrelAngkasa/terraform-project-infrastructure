locals {
  name                  = "networth-tracker-backend"
  image_uri             = "125905898704.dkr.ecr.ap-southeast-1.amazonaws.com/mynetworth-tracker:be-latest"

  backend_port          = var.backend_port
  backend_jwt_secret    = var.backend_jwt_secret
  backend_node_env      = var.backend_node_env
  backend_database_url  = var.backend_database_url
  backend_client_origin = var.backend_client_origin
}

module "lambda_backend" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.name
  description   = "My awesome backend lambda function"

  create_package = false

  package_type = "Image"
  architectures  = [ "x86_64" ]
  image_uri    = local.image_uri

  memory_size = 512
  timeout     = 15

  environment_variables = {
    PORT          = local.backend_port
    JWT_SECRET    = local.backend_jwt_secret
    NODE_ENV      = local.backend_node_env
    DATABASE_URL  = local.backend_database_url
    CLIENT_ORIGIN = local.backend_client_origin
  }

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
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    max_age           = 86400
  }
}