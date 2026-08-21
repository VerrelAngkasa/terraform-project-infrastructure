variable "backend_port" {
    type = number
}

variable "backend_jwt_secret" {
    type = string
}

variable "backend_node_env" {
    type = string
}

variable "backend_database_url" {
    type = string
}

variable "backend_client_origin" {
    type = string
}

variable "s3_bucket_domain_name" {
    type = string
}