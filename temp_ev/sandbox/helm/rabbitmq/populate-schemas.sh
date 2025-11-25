#!/bin/bash
# Script to populate schemas ConfigMap for BAP and BPP RabbitMQ deployments

set -e

NAMESPACE="${NAMESPACE:-ev-charging-sandbox}"
SCHEMAS_DIR="${SCHEMAS_DIR:-../../../schemas/beckn.one_deg_ev-charging/v2.0.0}"
RELEASE_BAP="${RELEASE_BAP:-ev-charging-rabbitmq-bap}"
RELEASE_BPP="${RELEASE_BPP:-ev-charging-rabbitmq-bpp}"

if [ ! -d "$SCHEMAS_DIR" ]; then
    echo "Error: Schemas directory not found: $SCHEMAS_DIR"
    echo "Please set SCHEMAS_DIR environment variable to the correct path"
    exit 1
fi

echo "Populating schemas ConfigMap from: $SCHEMAS_DIR"
echo "Namespace: $NAMESPACE"
echo "BAP Release: $RELEASE_BAP"
echo "BPP Release: $RELEASE_BPP"

# Get absolute paths to preserve directory structure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCHEMAS_DIR" = /* ]]; then
    SCHEMAS_DIR_ABS="$SCHEMAS_DIR"
else
    SCHEMAS_DIR_ABS="$(cd "$SCRIPT_DIR/$SCHEMAS_DIR" && pwd)"
fi
SCHEMAS_PARENT_DIR="$(dirname "$SCHEMAS_DIR_ABS")"  # .../schemas/beckn.one_deg_ev-charging
SCHEMAS_ROOT="$(dirname "$SCHEMAS_PARENT_DIR")"  # .../schemas/
SCHEMAS_DOMAIN="$(basename "$SCHEMAS_PARENT_DIR")"  # beckn.one_deg_ev-charging
SCHEMAS_VERSION="$(basename "$SCHEMAS_DIR_ABS")"  # v2.0.0

# Function to create ConfigMap with flat keys (initContainer will organize into directory structure)
create_schemas_configmap() {
    local cm_name=$1
    echo "Creating/updating $cm_name ConfigMap..."
    
    # Create ConfigMap with flat keys (just filenames)
    # The initContainer will copy these to the correct directory structure
    kubectl create configmap "$cm_name" \
        --from-file="$SCHEMAS_DIR_ABS" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Create or update BAP schemas ConfigMap
BAP_CONFIGMAP="${RELEASE_BAP}-onix-rabbitmq-schemas"
create_schemas_configmap "$BAP_CONFIGMAP"

# Create or update BPP schemas ConfigMap
BPP_CONFIGMAP="${RELEASE_BPP}-onix-rabbitmq-schemas"
create_schemas_configmap "$BPP_CONFIGMAP"

echo "Schemas ConfigMap populated successfully!"
echo ""
echo "To apply the changes, restart the pods:"
echo "  kubectl delete pod -n $NAMESPACE -l component=bap,app.kubernetes.io/instance=$RELEASE_BAP"
echo "  kubectl delete pod -n $NAMESPACE -l component=bpp,app.kubernetes.io/instance=$RELEASE_BPP"

