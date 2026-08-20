variable "lambda_backend_arn" {
    type = string
    description = "The ARN of the backend Lambda function passed from compute module"
}

variable "networth_backend_exec_role" {
    type = string
}

variable "cloudfront_distribution_arn" {
    type = string
}