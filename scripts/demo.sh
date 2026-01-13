#!/bin/bash
# Demo script: test the deployed API endpoints

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT/infra"

# Get API Gateway URL
GW_URL=$(terraform output -raw api_gateway_url)

if [ -z "$GW_URL" ]; then
    echo "Error: Could not get api_gateway_url from Terraform output"
    exit 1
fi

echo "Testing API Gateway at: $GW_URL"
echo ""

# Test health endpoint
echo "1. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "$GW_URL/v1/health")
echo "Response: $HEALTH_RESPONSE"
echo ""

# Create an item
echo "2. Creating an item..."
CREATE_RESPONSE=$(curl -s -X POST "$GW_URL/v1/items" \
  -H "Content-Type: application/json" \
  -d '{"name":"demo","ts":123}')

echo "Response: $CREATE_RESPONSE"
echo ""

# Extract ID from response (assuming jq is available, otherwise use grep/sed)
if command -v jq &> /dev/null; then
    ITEM_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id')
else
    # Fallback: extract ID using grep/sed
    ITEM_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
fi

if [ -z "$ITEM_ID" ] || [ "$ITEM_ID" = "null" ]; then
    echo "Error: Could not extract item ID from response"
    echo "Full response: $CREATE_RESPONSE"
    exit 1
fi

echo "Created item with ID: $ITEM_ID"
echo ""

# Get the item back
echo "3. Retrieving item with ID: $ITEM_ID..."
GET_RESPONSE=$(curl -s "$GW_URL/v1/items/$ITEM_ID")
echo "Response: $GET_RESPONSE"
echo ""

echo "✅ Demo completed successfully!"
