variable "backend_port" {
    type        = number
    description = "Port for the backend service"
    default     = 3000
}

variable "backend_jwt_secret" {
    type        = string
    description = "JWT secret for auth"
    sensitive   = true # Hides the value in CLI output
}

variable "backend_node_env" {
    type        = string
    description = "Node environment for backend"
    default = "development"
}

variable "backend_database_url" {
    type        = string
    description = "Supabase transaction pool string"
    sensitive   = true
}

variable "backend_client_origin" {
    type        = string
    description = "Client origin for CORS frontend"
    default     = "http://localhost:5173"
}