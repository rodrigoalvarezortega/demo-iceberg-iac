#!/bin/bash
# Full deployment script: provision infra, build image, update service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if project_id is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <PROJECT_ID>"
    exit 1
fi

PROJECT_ID=$1

echo "=== Step 1: Provision infrastructure (first pass) ==="
cd "$PROJECT_ROOT/infra"
terraform init
terraform apply -auto-approve -var="project_id=$PROJECT_ID"

echo ""
echo "=== Step 2: Build and push container image ==="
cd "$PROJECT_ROOT"
./scripts/build_push.sh

echo ""
echo "=== Step 3: Update Cloud Run with the actual image ==="
cd "$PROJECT_ROOT/infra"
terraform apply -auto-approve -var="project_id=$PROJECT_ID" -var="use_placeholder_image=false"

echo ""
echo "=== Deployment complete! ==="
echo ""
echo "API Gateway URL:"
terraform output api_gateway_url
echo ""
echo "⚠️  IMPORTANT: API Gateway can take 5-10 minutes to fully propagate."
echo "Wait before testing the endpoints."
