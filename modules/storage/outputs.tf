output "iam_access_key_id" {
    value       = aws_iam_access_key.github_actions_key.id
    description = "The AWS IAM access key for the github actions pipeline"
}

output "iam_secret_access_key" {
    value     = aws_iam_access_key.github_actions_key.secret
    sensitive = true
}

output "ecr_repository_arn" {
    value = module.ecr.repository_arn
}

output "s3_bucket_domain_name" {
    value = module.s3_frontend_bucket.s3_bucket_bucket_regional_domain_name
}