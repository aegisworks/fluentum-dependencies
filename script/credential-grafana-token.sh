#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the credentials
source "$DIR/credential.sh"

# Grafana service account
SERVICE_ACCOUNT_NAME="fluentum-sa"
SERVICE_ACCOUNT_ROLE="Admin"
TOKEN_NAME="fluentum-token"

# Function to create Grafana service account
create_grafana_service_account() {
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"name\":\"${SERVICE_ACCOUNT_NAME}\", \"role\":\"${SERVICE_ACCOUNT_ROLE}\"}" \
        -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" "${GRAFANA_URL}/api/serviceaccounts")
    echo "$response"
}

# Function to create Grafana API token for the service account
create_grafana_token_for_service_account() {
    local service_account_id=$1
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"name\":\"${TOKEN_NAME}\"}" \
        -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" "${GRAFANA_URL}/api/serviceaccounts/${service_account_id}/tokens")
    echo "$response"
}

# Create service account
service_account_response=$(create_grafana_service_account)
service_account_id=$(echo "$service_account_response" | jq -r '.id') # Extracting the service account ID

# Check if service account ID is available
if [ -n "$service_account_id" ] && [ "$service_account_id" != "null" ]; then
    # Create token for the service account
    token_response=$(create_grafana_token_for_service_account "$service_account_id")
    echo "Token creation response: $token_response"
else
    echo "Failed to create service account. Response: $service_account_response"
fi
