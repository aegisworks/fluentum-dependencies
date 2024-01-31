#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the credentials
source "$DIR/credential.sh"

# Create a Kubernetes secret from the hardcoded password
kubectl create secret generic grafana-credentials --from-literal=admin-password=$GRAFANA_PASSWORD --dry-run=client -o yaml > "$DIR/../grafana/grafana-credentials.yaml"

# Remove the creationTimestamp line using sed
sed -i '/creationTimestamp/d' "$DIR/../grafana/grafana-credentials.yaml"

# Check if the Kubernetes secret file was created successfully
if [ ! -f "$DIR/../grafana/grafana-credentials.yaml" ]; then
    echo "Failed to create Kubernetes secret file"
    exit 1
fi

echo "Successfully created grafana credentials secret file."
