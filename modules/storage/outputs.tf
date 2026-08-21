output "iam_secret_access_key" {
    value     = aws_iam_access_key.github_actions_key.secret
    sensitive = true
}

output "s3_bucket_domain_name" {
    value = module.s3_frontend_bucket.s3_bucket_bucket_regional_domain_name
}