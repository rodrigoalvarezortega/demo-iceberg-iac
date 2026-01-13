# API Gateway API
resource "google_api_gateway_api" "api" {
  provider     = google-beta
  api_id       = "${var.service_name}-api"
  project      = var.project_id
  display_name = "${var.service_name} API"
}

# API Gateway API Config
resource "google_api_gateway_api_config" "api_config" {
  provider      = google-beta
  api           = google_api_gateway_api.api.api_id
  api_config_id = "${var.service_name}-config"
  project       = var.project_id
  display_name  = "${var.service_name} API Config"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(templatefile("${path.module}/openapi.yaml.tpl", {
        cloud_run_url = google_cloud_run_v2_service.api.uri
      }))
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.cloud_run_sa.email
    }
  }

  depends_on = [
    google_api_gateway_api.api,
    google_cloud_run_v2_service.api
  ]
}

# API Gateway Gateway
resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = "${var.service_name}-gateway"
  project    = var.project_id
  region     = var.region
  display_name = "${var.service_name} Gateway"

  depends_on = [google_api_gateway_api_config.api_config]
}
