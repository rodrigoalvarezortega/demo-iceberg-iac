# GCP Serverless Demo (Terraform): API Gateway → Cloud Run (Docker) → Firestore

This repo is a **minimal, company-demo** equivalent to **AWS API Gateway → Lambda (Docker image) → DynamoDB**, implemented on **Google Cloud** as:

* **GCP API Gateway** (front door) ([Google Cloud Documentation][1])
* **Cloud Run (v2)** running a **Docker container** (serverless compute) ([Google Cloud][2])
* **Firestore (Native mode)** as the **NoSQL database** ([registry.terraform.io][3])

---

## 1) Architecture

```
┌─────────┐
│ Client  │
└────┬────┘
     │ HTTPS
     ▼
┌─────────────────────┐
│  GCP API Gateway    │  ← Routes requests via OpenAPI + x-google-backend
│  (Edge / Frontend)  │
└────┬────────────────┘
     │ HTTP
     ▼
┌─────────────────────┐
│  Cloud Run (v2)     │  ← Serverless container (scales to zero)
│  Docker Container   │
└────┬────────────────┘
     │ gRPC/HTTP
     ▼
┌─────────────────────┐
│  Firestore (Native) │  ← NoSQL database (serverless)
│  (default database) │
└─────────────────────┘
```

API Gateway routes to the backend using `x-google-backend` and can append paths to the backend address. ([Google Cloud Documentation][4])

---

## 2) What Cursor must generate (deliverables)

### Infra (Terraform)

A single `infra/` folder that provisions:

1. **Project services enabled** (`google_project_service`) including:

* `run.googleapis.com`
* `apigateway.googleapis.com`
* `artifactregistry.googleapis.com`
* `firestore.googleapis.com`
* `cloudbuild.googleapis.com` (optional if we use Cloud Build for push)
* `iam.googleapis.com`
* `servicemanagement.googleapis.com`
* `servicecontrol.googleapis.com`

> Enabling services via Terraform is a common requirement for API Gateway deployments. ([Stack Overflow][5])

2. **Artifact Registry Docker repository** (for the container image) using `google_artifact_registry_repository`.

   * Require `hashicorp/google` provider **>= 5.0.0** (per Google docs). ([Google Cloud Documentation][6])

3. **Firestore database (Native mode)** using `google_firestore_database`:

* `database_id = "(default)"`
* location configurable (default: `southamerica-east1`)
* note: location is **not changeable** after creation (important for demos)

Firestore supports `southamerica-east1` among other locations. ([Google Cloud][7])
Terraform resource exists as `google_firestore_database`. ([registry.terraform.io][3])

4. **Cloud Run v2 service** using `google_cloud_run_v2_service` ([registry.terraform.io][8])

* points to an image in Artifact Registry (var-driven)
* sets env vars (example uses standard patterns) ([Google Cloud Documentation][9])
* uses a dedicated runtime service account

5. **IAM**

* Grant Cloud Run runtime service account permission to use Firestore:

  * `roles/datastore.user` (or equivalent minimal needed)
* Allow unauthenticated invocation for demo simplicity (optional toggle):

  * `google_cloud_run_v2_service_iam_member` with `allUsers` → `roles/run.invoker`

6. **API Gateway** resources:

* `google_api_gateway_api`
* `google_api_gateway_api_config`
* `google_api_gateway_gateway`

**Important**: API Gateway resources are **beta** in Terraform Registry and should be managed with the **google-beta provider**. ([registry.terraform.io][10])

The API config must be generated from an **OpenAPI spec** that routes to the Cloud Run URL using `x-google-backend`. ([Google Cloud Documentation][11])

### App (minimal container)

A `app/` folder with a tiny HTTP API (FastAPI or Express) that:

* `GET /v1/health` → `{ "ok": true }`
* `POST /v1/items` → creates a Firestore document and returns `{ "id": "...", "data": {...} }`
* `GET /v1/items/{id}` → returns the saved document or 404

App must run on Cloud Run by listening on `$PORT` (8080) inside Docker.

---

## 3) Repo structure (Cursor should create)

```
.
├─ app/
│  ├─ main.py (or index.js)
│  ├─ requirements.txt (or package.json)
│  └─ Dockerfile
├─ infra/
│  ├─ main.tf
│  ├─ providers.tf
│  ├─ variables.tf
│  ├─ outputs.tf
│  ├─ iam.tf
│  ├─ apis.tf
│  ├─ openapi.yaml.tpl
│  └─ README.md (optional)
├─ scripts/
│  ├─ build_push.sh
│  ├─ deploy.sh (optional: automates full deployment flow)
│  └─ demo.sh
└─ README.md (this file)
```

---

## 4) Default regions (opinionated for LatAm demos)

* `region`: `southamerica-east1` (Cloud Run + Artifact Registry)
  Cloud Run supports `southamerica-east1`. ([Google Cloud Documentation][12])
* `firestore_location`: `southamerica-east1` (Firestore) ([Google Cloud][7])

> Keep them aligned for latency and to avoid cross-region data transfer surprises.

---

## 5) Terraform design constraints (keep it simple)

### Required inputs (`infra/variables.tf`)

* `project_id` (string) **required**
* `region` (string) default `southamerica-east1`
* `service_name` (string) default `demo-api`
* `artifact_repo_id` (string) default `demo-repo`
* `image_tag` (string) default `v1`
* `deploy_public` (bool) default `true` (allows `allUsers` invoke)
* `firestore_location` (string) default `southamerica-east1`

### Computed locals

* `image_uri = "${region}-docker.pkg.dev/${project_id}/${artifact_repo_id}/${service_name}:${image_tag}"`

### Outputs (`infra/outputs.tf`)

* `cloud_run_url`
* `api_gateway_url` (use gateway default hostname)
* `image_uri`

---

## 6) OpenAPI template (API Gateway → Cloud Run)

Cursor should generate `infra/openapi.yaml.tpl` and render it with `templatefile()` injecting `cloud_run_url`.

Must include:

* `x-google-backend.address: ${cloud_run_url}`
* `path_translation: APPEND_PATH_TO_ADDRESS` (recommended) ([Google Cloud Documentation][4])

Reference: API Gateway + Cloud Run getting started guide. ([Google Cloud Documentation][11])

---

## 7) Quickstart (what the demo user runs)

### Prereqs

* Terraform installed
* gcloud installed and authenticated
* A GCP project with billing enabled
* Permissions to create: API Gateway, Cloud Run, IAM, Artifact Registry, Firestore

### Steps

#### 1) Authenticate + set project

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

#### 2) Provision infra (first pass)

This creates the infrastructure but Cloud Run may use a placeholder image initially:

```bash
cd infra
terraform init
terraform apply -auto-approve -var="project_id=<PROJECT_ID>"
```

**Note**: The first `terraform apply` creates all resources. If Cloud Run is configured to require an existing image, you may need to use a placeholder or make the image optional initially.

#### 3) Build & push the container image

Use the image URI produced by Terraform:

```bash
export IMAGE_URI="$(cd infra && terraform output -raw image_uri)"
cd app
gcloud builds submit --tag "$IMAGE_URI" .
```

This step builds your Docker container and pushes it to Artifact Registry.

#### 4) Update Cloud Run with the actual image

```bash
cd ../infra
terraform apply -auto-approve -var="project_id=<PROJECT_ID>"
```

This updates the Cloud Run service to use the newly built image.

#### 5) Wait for API Gateway propagation

**Important**: API Gateway can take **5-10 minutes** to fully propagate after creation. If you get 404 or connection errors immediately after deployment, wait a few minutes and retry.

You can check the gateway status:
```bash
gcloud api-gateway gateways describe <GATEWAY_NAME> --location=<REGION> --project=<PROJECT_ID>
```

> **Alternative**: Use `scripts/deploy.sh` (if implemented) to automate steps 2-4 in a single command.


---

## 8) Demo verification (curl)

**Wait 5-10 minutes after deployment** for API Gateway to fully propagate, then:

```bash
export GW_URL="$(cd infra && terraform output -raw api_gateway_url)"
curl -s "$GW_URL/v1/health" | jq
```

Expected response: `{"ok": true}`

Create an item:

```bash
curl -s -X POST "$GW_URL/v1/items" \
  -H "Content-Type: application/json" \
  -d '{"name":"demo","ts":123}' | jq
```

Get it back (replace `<ID>` with the ID from the previous response):

```bash
curl -s "$GW_URL/v1/items/<ID>" | jq
```

---

## 9) Cleanup (destroy resources)

To remove all resources created by this demo:

```bash
cd infra
terraform destroy -auto-approve -var="project_id=<PROJECT_ID>"
```

**Note**: This will delete:
- API Gateway (gateway, config, API)
- Cloud Run service
- Firestore database (⚠️ **all data will be lost**)
- Artifact Registry repository (⚠️ **all images will be deleted**)
- IAM bindings created by Terraform

If you want to keep the Firestore database or images, remove those resources from Terraform state before destroying, or manually delete them via the GCP Console.

---

## 10) Troubleshooting

### Common Issues

#### API Gateway returns 404 or connection errors

**Cause**: API Gateway takes 5-10 minutes to propagate after creation.

**Solution**: Wait 5-10 minutes and retry. Check gateway status:
```bash
gcloud api-gateway gateways list --location=<REGION> --project=<PROJECT_ID>
```

#### Cloud Run service fails to start

**Possible causes**:
- Container image doesn't exist in Artifact Registry
- Service account lacks Firestore permissions
- Container not listening on `$PORT` (default 8080)

**Solution**:
- Verify image exists: `gcloud artifacts docker images list --repository=<REPO> --location=<REGION>`
- Check service account has `roles/datastore.user`
- Verify app listens on `$PORT` environment variable

#### Terraform fails with "API not enabled"

**Cause**: Required GCP APIs are not enabled in the project.

**Solution**: The Terraform code should enable services automatically, but if it fails:
```bash
gcloud services enable run.googleapis.com apigateway.googleapis.com artifactregistry.googleapis.com firestore.googleapis.com
```

#### Firestore location cannot be changed

**Cause**: Firestore database location is immutable after creation.

**Solution**: Destroy and recreate with the correct location, or use a new project.

#### Permission denied errors

**Cause**: Insufficient IAM permissions for the authenticated user.

**Solution**: Ensure your account has:
- `roles/owner` or `roles/editor` on the project, OR
- Specific permissions: `run.admin`, `apigateway.admin`, `artifactregistry.admin`, `datastore.admin`, `iam.serviceAccountUser`

#### Service account cannot access Firestore

**Cause**: Cloud Run service account missing Firestore permissions.

**Solution**: Verify IAM binding exists:
```bash
gcloud projects get-iam-policy <PROJECT_ID> --flatten="bindings[].members" --filter="bindings.members:serviceAccount:*"
```

The service account should have `roles/datastore.user` or equivalent.

---

## 11) Non-goals (to keep it demo-simple)

* No custom domain
* No JWT / OAuth setup
* No VPC connectors
* No CI/CD pipelines
* No multi-env (dev/stage/prod)

These can be added later, but they distract from the “AWS-equivalent serverless” story.

---

## 12) Definition of Done (acceptance criteria)

Cursor-generated repo is correct when:

1. `terraform apply` succeeds with only `project_id` provided.
2. Cloud Run service is deployed via `google_cloud_run_v2_service`. ([registry.terraform.io][8])
3. API Gateway is deployed using beta resources (`google-beta` provider). ([registry.terraform.io][10])
4. The API Gateway endpoint successfully routes to Cloud Run using the OpenAPI `x-google-backend` mapping. ([Google Cloud Documentation][11])
5. `POST /v1/items` and `GET /v1/items/{id}` work against Firestore.

---

## 13) Notes for the presenter (enterprise demo talk-track)

* “This is the GCP equivalent of API Gateway + Lambda + DynamoDB.”
* “Cloud Run is the serverless runtime for containers; it scales to zero and scales out automatically.” ([Google Cloud][2])
* “API Gateway centralizes routing and policy at the edge.” ([Google Cloud Documentation][1])
* “Firestore gives us a serverless NoSQL backing store.”

