output "iam_secret_access_key" {
    value     = module.storage.iam_secret_access_key
    sensitive = true
}

output "api_endpoint" {
    value = module.compute.api_endpoint
}