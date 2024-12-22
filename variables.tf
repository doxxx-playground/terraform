variable "kube_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "api_image_repository" {
  description = "API Docker image repository"
  type        = string
}

variable "api_image_tag" {
  description = "API Docker image tag"
  type        = string
  default     = "latest"
}
variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "mydb"
}

variable "postgres_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "myuser"
}
