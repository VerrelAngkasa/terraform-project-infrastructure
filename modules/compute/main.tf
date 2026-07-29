locals {
  name = "networth-tracker-backend"
}

module "lambda_function_backend" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.name
  description   = "My awesome backend lambda function"

  create_package = false
  package_type = "Image"
  image_uri    = "125905898704.dkr.ecr.ap-southeast-1.amazonaws.com/mynetworth-tracker:latest"

  tags = {
    Terraform   = "true"
  }
}