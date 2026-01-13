variable "project_id" {
  description = "GCP Project ID (required)"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run and Artifact Registry"
  type        = string
  default     = "southamerica-east1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "demo-api"
}

variable "artifact_repo_id" {
  description = "Artifact Registry repository ID"
  type        = string
  default     = "demo-repo"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "v1"
}

variable "deploy_public" {
  description = "Allow unauthenticated invocation of Cloud Run service"
  type        = bool
  default     = true
}

variable "firestore_location" {
  description = "Location for Firestore database"
  type        = string
  default     = "southamerica-east1"
}

variable "use_placeholder_image" {
  description = "Use a placeholder image for initial deployment (set to false after building actual image)"
  type        = bool
  default     = true
}
