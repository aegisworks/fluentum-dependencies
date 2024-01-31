#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the credentials
source "$DIR/credential.sh"

# Create a Kubernetes secret for PostgreSQL
kubectl create secret generic postgresql-credentials --from-literal=superUserPassword=$POSTGRES_SUPERUSER_PASSWORD --from-literal=replicationUserPassword=$POSTGRES_REPLICATION_PASSWORD --dry-run=client -o yaml > "$DIR/../postgres/postgresql-credentials.yaml"

# Remove the creationTimestamp line using sed
sed -i '/creationTimestamp/d' "$DIR/../postgres/postgresql-credentials.yaml"

# Check if the PostgreSQL Kubernetes secret file was created successfully
if [ ! -f "$DIR/../postgres/postgresql-credentials.yaml" ]; then
    echo "Failed to create PostgreSQL Kubernetes secret file"
    exit 1
fi

echo "Successfully created PostgreSQL credentials secret file."
