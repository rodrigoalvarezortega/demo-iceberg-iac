# GCP Serverless Demo (Terraform): API Gateway → Cloud Run (Docker) → Firestore

This repo is a **minimal, company-demo** equivalent to **AWS API Gateway → Lambda (Docker image) → DynamoDB**, implemented on **Google Cloud** as:

* **GCP API Gateway** (front door)
* **Cloud Run (v2)** running a **Docker container** (serverless compute)
* **Firestore (Native mode)** as the **NoSQL database**

## Architecture

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

## Quick Start

### Prerequisites

* Terraform installed
* `gcloud` CLI installed and authenticated
* A GCP project with billing enabled
* Permissions to create: API Gateway, Cloud Run, IAM, Artifact Registry, Firestore

### 0. Setup your environment (First time only)

**Quick setup (instala automáticamente gcloud y Terraform si no los tienes):**
```bash
# Linux/Mac
chmod +x scripts/setup.sh
./scripts/setup.sh

# Windows (PowerShell)
.\scripts\setup.ps1
```

El script detectará si faltan herramientas y las instalará automáticamente usando:
- **Windows**: winget o chocolatey
- **Linux**: apt-get, yum, o brew
- **Mac**: Homebrew

**Or manual setup:**
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

📖 **¿Dónde obtener las credenciales?** Ver [SETUP.md](SETUP.md) para detalles completos.

### 1. Authenticate and set project (if not using setup script)

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

### 2. Deploy everything (automated)

```bash
./scripts/deploy.sh <PROJECT_ID>
```

This script will:
1. Provision all infrastructure with Terraform
2. Build and push the Docker image
3. Update Cloud Run with the new image

### 3. Wait for API Gateway propagation

**Important**: API Gateway can take **5-10 minutes** to fully propagate after creation.

Check gateway status:
```bash
gcloud api-gateway gateways list --location=southamerica-east1 --project=<PROJECT_ID>
```

### 4. Test the API

```bash
./scripts/demo.sh
```

Or manually:

```bash
export GW_URL="$(cd infra && terraform output -raw api_gateway_url)"

# Health check
curl -s "$GW_URL/v1/health" | jq

# Create an item
curl -s -X POST "$GW_URL/v1/items" \
  -H "Content-Type: application/json" \
  -d '{"name":"demo","ts":123}' | jq

# Get item (replace <ID> with ID from previous response)
curl -s "$GW_URL/v1/items/<ID>" | jq
```

## Manual Deployment Steps

If you prefer to deploy manually:

### Step 1: Provision infrastructure

```bash
cd infra
terraform init
terraform apply -auto-approve -var="project_id=<PROJECT_ID>"
```

### Step 2: Build and push container image

```bash
./scripts/build_push.sh
```

### Step 3: Update Cloud Run

```bash
cd infra
terraform apply -auto-approve -var="project_id=<PROJECT_ID>"
```

## Cleanup

To remove all resources:

```bash
cd infra
terraform destroy -auto-approve -var="project_id=<PROJECT_ID>"
```

**Warning**: This will delete:
- API Gateway (gateway, config, API)
- Cloud Run service
- Firestore database (⚠️ **all data will be lost**)
- Artifact Registry repository (⚠️ **all images will be deleted**)
- IAM bindings created by Terraform

## Project Structure

```
.
├─ app/
│  ├─ main.py              # FastAPI application
│  ├─ requirements.txt     # Python dependencies
│  └─ Dockerfile           # Container definition
├─ infra/
│  ├─ main.tf              # Main infrastructure resources
│  ├─ providers.tf        # Terraform providers
│  ├─ variables.tf         # Input variables
│  ├─ outputs.tf          # Output values
│  ├─ iam.tf              # IAM bindings
│  ├─ apis.tf             # API Gateway resources
│  └─ openapi.yaml.tpl    # OpenAPI template for API Gateway
├─ scripts/
│  ├─ build_push.sh       # Build and push Docker image
│  ├─ deploy.sh           # Full deployment automation
│  └─ demo.sh             # Test API endpoints
├─ guide.md               # Detailed implementation guide
└─ README.md              # This file
```

## API Endpoints

* `GET /v1/health` → Returns `{"ok": true}`
* `POST /v1/items` → Creates a Firestore document and returns `{"id": "...", "data": {...}}`
* `GET /v1/items/{id}` → Returns the saved document or 404

## Configuration

Default values (can be overridden with Terraform variables):

* `region`: `southamerica-east1`
* `service_name`: `demo-api`
* `artifact_repo_id`: `demo-repo`
* `image_tag`: `v1`
* `firestore_location`: `southamerica-east1`
* `deploy_public`: `true` (allows unauthenticated access)

## Troubleshooting

See [guide.md](guide.md) section 10 for common issues and solutions.

Common issues:
- **API Gateway 404**: Wait 5-10 minutes for propagation
- **Cloud Run fails to start**: Check image exists and service account has Firestore permissions
- **Permission errors**: Ensure your account has required IAM roles

## Notes for Presenters

* "This is the GCP equivalent of API Gateway + Lambda + DynamoDB."
* "Cloud Run is the serverless runtime for containers; it scales to zero and scales out automatically."
* "API Gateway centralizes routing and policy at the edge."
* "Firestore gives us a serverless NoSQL backing store."

## License

This is a demo project for educational purposes.
