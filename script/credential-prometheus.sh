#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the credentials
source "$DIR/credential.sh"

# Check if htpasswd is available
if ! command -v htpasswd &> /dev/null
then
    echo "htpasswd could not be found, please install it."
    exit 1
fi

# Generate htpasswd file
echo $PROMETHEUS_PASSWORD | htpasswd -ci "$DIR/auth" $PROMETHEUS_USERNAME

# Check if htpasswd file was created successfully
if [ ! -f "$DIR/auth" ]; then
    echo "Failed to create htpasswd file"
    exit 1
fi

# Create a Kubernetes secret from the htpasswd file
kubectl create secret generic prometheus-credentials --from-file="$DIR/auth" --dry-run=client -o yaml > "$DIR/../prometheus/prometheus-credentials.yaml"

# Remove the creationTimestamp line using sed
sed -i '/creationTimestamp/d' "$DIR/../prometheus/prometheus-credentials.yaml"

# Check if the Kubernetes secret file was created successfully
if [ ! -f "$DIR/../prometheus/prometheus-credentials.yaml" ]; then
    echo "Failed to create Kubernetes secret file"
    exit 1
fi

# Remove the htpasswd file
rm "$DIR/auth"

echo "Successfully created Prometheus secret file."
