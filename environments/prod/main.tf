terraform {
    required_version = ">= 1.5.7"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.28"
        }
    }

    backend s3 {
        bucket = "terraform-project-infrastructure"
        key    = "prod/networth-tracker.tfstate"
        region = "ap-southeast-1"
        encrypt = true
    }
}

provider aws {
    region = var.aws_region
}

module storage {
    source = "../../modules/storage"

    lambda_backend_arn = module.compute.lambda_backend_arn
    networth_backend_lambda_role_arn = module.compute.networth_backend_lambda_role_arn
    cloudfront_distribution_arn = module.compute.cloudfront_distribution_arn
}

module compute {
    source = "../../modules/compute"

    s3_bucket_domain_name = module.storage.s3_bucket_domain_name

    backend_port          = var.backend_port
    backend_jwt_secret    = var.backend_jwt_secret
    backend_node_env      = var.backend_node_env
    backend_database_url  = var.backend_database_url
    backend_client_origin = var.backend_client_origin
    backend_api_endpoint  = var.backend_api_endpoint
}