#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the credentials
source "$DIR/credential.sh"

# Secret name must be fluentum-es-elastic-user, this is corresponding to the Elasticsearch CRD name
# Create a Kubernetes secret from the htpasswd file
kubectl create secret generic fluentum-es-elastic-user --from-literal=$ELASTIC_USERNAME=$ELASTIC_PASSWORD --dry-run=client -o yaml > "$DIR/../elasticsearch/fluentum-es-elastic-user.yaml"

# Remove the creationTimestamp line using sed
sed -i '/creationTimestamp/d' "$DIR/../elasticsearch/fluentum-es-elastic-user.yaml"

# Check if the Kubernetes secret file was created successfully
if [ ! -f "$DIR/../elasticsearch/fluentum-es-elastic-user.yaml" ]; then
    echo "Failed to create Kubernetes secret file"
    exit 1
fi

echo "Successfully created elastic credentials secret file."
