# Infrastructure as Code (Terraform)

This directory contains all Terraform configuration files for provisioning the GCP serverless infrastructure.

## Files

- `providers.tf` - Terraform provider configuration (google and google-beta)
- `variables.tf` - Input variables
- `main.tf` - Main infrastructure resources (APIs, Artifact Registry, Firestore, Cloud Run)
- `iam.tf` - IAM bindings for service accounts
- `apis.tf` - API Gateway resources (uses google-beta provider)
- `openapi.yaml.tpl` - OpenAPI template for API Gateway configuration
- `outputs.tf` - Output values (URLs, image URI, etc.)

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan changes

```bash
terraform plan -var="project_id=<PROJECT_ID>"
```

### Apply infrastructure

```bash
terraform apply -var="project_id=<PROJECT_ID>"
```

### Destroy infrastructure

```bash
terraform destroy -var="project_id=<PROJECT_ID>"
```

## Variables

See `variables.tf` for all available variables. Required variable:
- `project_id` - GCP Project ID

Optional variables (with defaults):
- `region` - GCP region (default: `southamerica-east1`)
- `service_name` - Cloud Run service name (default: `demo-api`)
- `artifact_repo_id` - Artifact Registry repository ID (default: `demo-repo`)
- `image_tag` - Docker image tag (default: `v1`)
- `deploy_public` - Allow unauthenticated access (default: `true`)
- `firestore_location` - Firestore database location (default: `southamerica-east1`)
- `use_placeholder_image` - Use placeholder image for initial deploy (default: `true`)

## Outputs

After applying, you can get outputs with:

```bash
terraform output
terraform output -raw api_gateway_url
terraform output -raw cloud_run_url
terraform output -raw image_uri
```
