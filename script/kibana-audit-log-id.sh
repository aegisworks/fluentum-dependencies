#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the credentials
source "$DIR/credential.sh"

# Check if any credential is set to '<changeme>'
if [ "$ELASTIC_PASSWORD" == "<changeme>" ]; then
    echo "One or more credentials are set to the default 'changeme'. Update the credentials before proceeding."
    exit 1
fi

# Define data view details
DATA_VIEW_BODY="{\"data_view\":{\"title\":\"fluentum-audit-log-*\",\"name\":\"fluentum-audit-log\",\"timeFieldName\":\"@timestamp\"}}"

# Create audit log index pattern id
RESPONSE=$(curl -X POST "$KIBANA_URL/api/data_views/data_view" -H "Content-Type: application/json" -H "kbn-xsrf: whatever" -u "$ELASTIC_USERNAME:$ELASTIC_PASSWORD" -d "$DATA_VIEW_BODY")

# Find created id in the response
DATA_VIEW_ID=$(echo "$RESPONSE" | jq '.data_view.id')

if [[ "$DATA_VIEW_ID" != "null" ]]; then
  # .id found and response successful
  echo "Data view created successfully! ID: $DATA_VIEW_ID"
else
  echo "Error creating data view! Response: $RESPONSE"
fi
