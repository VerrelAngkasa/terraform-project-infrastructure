output "iam_secret_access_key" {
    value       = module.storage.iam_secret_access_key
    description = "The AWS IAM secret key for the github actions pipeline"
    sensitive   = true
}

output "api_endpoint" {
    value       = module.compute.api_endpoint
    description = "The direct HTTPS endpoint URL for your Express backend"
}

output "s3_bucket_domain_name" {
    value       = module.storage.s3_bucket_domain_name
    description = "The S3 bucket domain name for the frontend SPA"
}

output "cloudfront_distribution_domain_name" {
    value       = module.compute.cloudfront_distribution_domain_name
    description = "The domain name of the CloudFront distribution for the frontend SPA"
}