output "iam_secret_access_key" {
    value     = module.storage.iam_secret_access_key
    description = "The AWS IAM secret key for the github actions pipeline"
    sensitive = true
}

output "api_endpoint" {
    value = module.compute.api_endpoint
    description = "The direct HTTPS endpoint URL for your Express backend"
}