locals {
  # Use placeholder image for initial deploy, then switch to actual image
  placeholder_image = "gcr.io/cloudrun/hello"
  actual_image_uri  = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_id}/${var.service_name}:${var.image_tag}"
  image_uri         = var.use_placeholder_image ? local.placeholder_image : local.actual_image_uri
}

# Enable required GCP APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "apigateway.googleapis.com",
    "artifactregistry.googleapis.com",
    "firestore.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
}

# Artifact Registry Docker repository
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = var.artifact_repo_id
  description   = "Docker repository for ${var.service_name}"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}

# Firestore database (Native mode)
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.required_apis]
}

# Service account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Cloud Run service account for ${var.service_name}"
  description  = "Service account used by Cloud Run to access Firestore"

  depends_on = [google_project_service.required_apis]
}

# Cloud Run v2 service
resource "google_cloud_run_v2_service" "api" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = local.image_uri

      ports {
        container_port = 8080
      }

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_artifact_registry_repository.docker_repo
  ]
}
