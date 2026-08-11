output "iam_access_key_id" {
    value       = aws_iam_access_key.github_actions_key.id
    description = "The AWS IAM access key for the github actions pipeline"
}

output "iam_secret_access_key" {
    value     = aws_iam_access_key.github_actions_key.secret
    sensitive = true
}