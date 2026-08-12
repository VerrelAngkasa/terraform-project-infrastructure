output "api_endpoint" {
    value = aws_lambda_function_url.backend_url.function_url
}

output "lambda_backend_arn" {
    value = module.lambda_backend.lambda_function_arn
}

output "networth_backend_exec_role" {
    value = aws_iam_role.networth_backend_exec_role.arn
}