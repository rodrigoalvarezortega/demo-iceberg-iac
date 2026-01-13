# Grant Cloud Run service account permission to use Firestore
resource "google_project_iam_member" "cloud_run_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"

  depends_on = [google_service_account.cloud_run_sa]
}

# Allow unauthenticated invocation (optional, controlled by deploy_public variable)
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count    = var.deploy_public ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [google_cloud_run_v2_service.api]
}
