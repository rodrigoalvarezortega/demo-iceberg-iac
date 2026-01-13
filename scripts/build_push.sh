#!/bin/bash
# Build and push Docker image to Artifact Registry

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get image URI from Terraform output
cd "$PROJECT_ROOT/infra"
IMAGE_URI=$(terraform output -raw image_uri)

if [ -z "$IMAGE_URI" ]; then
    echo "Error: Could not get image_uri from Terraform output"
    echo "Make sure you've run 'terraform apply' first"
    exit 1
fi

echo "Building and pushing image: $IMAGE_URI"
cd "$PROJECT_ROOT/app"

# Build and push using Cloud Build
gcloud builds submit --tag "$IMAGE_URI" .

echo "Image pushed successfully: $IMAGE_URI"
