output "cloud_run_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.api.uri
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${google_api_gateway_gateway.gateway.default_hostname}"
}

output "image_uri" {
  description = "Full URI of the container image in Artifact Registry"
  value       = local.actual_image_uri
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run_sa.email
}
