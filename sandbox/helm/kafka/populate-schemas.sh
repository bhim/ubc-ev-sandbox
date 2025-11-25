#!/bin/bash
# Script to populate schemas ConfigMap for BAP and BPP Kafka deployments

set -e

NAMESPACE="${NAMESPACE:-ev-charging-sandbox}"
# Default schemas directory - adjust path relative to script location
# From sandbox/helm/kafka/, go up 3 levels to project root, then into schemas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
SCHEMAS_DIR="${SCHEMAS_DIR:-$PROJECT_ROOT/schemas/beckn.one_deg_ev-charging/v2.0.0}"
RELEASE_BAP="${RELEASE_BAP:-ev-charging-kafka-bap}"
RELEASE_BPP="${RELEASE_BPP:-ev-charging-kafka-bpp}"

if [ ! -d "$SCHEMAS_DIR" ]; then
    echo "Error: Schemas directory not found: $SCHEMAS_DIR"
    echo "Please set SCHEMAS_DIR environment variable to the correct path"
    exit 1
fi

echo "Populating schemas ConfigMap from: $SCHEMAS_DIR"
echo "Namespace: $NAMESPACE"
echo "BAP Release: $RELEASE_BAP"
echo "BPP Release: $RELEASE_BPP"

# Create or update BAP schemas ConfigMap
# Preserve directory structure: beckn.one_deg_ev-charging/v2.0.0/schema.json
BAP_CONFIGMAP="${RELEASE_BAP}-onix-kafka-schemas"
echo "Creating/updating $BAP_CONFIGMAP ConfigMap..."
# Get the parent directory (beckn.one_deg_ev-charging) and version directory (v2.0.0)
SCHEMAS_PARENT_DIR="$(dirname "$SCHEMAS_DIR")"  # schemas/beckn.one_deg_ev-charging
SCHEMAS_DOMAIN="$(basename "$SCHEMAS_PARENT_DIR")"  # beckn.one_deg_ev-charging
SCHEMAS_VERSION="$(basename "$SCHEMAS_DIR")"  # v2.0.0
SCHEMAS_ROOT="$(dirname "$SCHEMAS_PARENT_DIR")"  # schemas/

# Create ConfigMap with flat structure (initContainer will organize into directory structure)
# Since ConfigMap keys cannot contain slashes, we'll use flat keys and let initContainer organize them
# Preserve Helm metadata if ConfigMap already exists (created by Helm chart)
cd "$SCHEMAS_DIR"

# Function to create/update ConfigMap while preserving Helm metadata
create_or_update_configmap() {
    local cm_name=$1
    local release_name=$2
    
    # Check if Helm release exists and is deployed (not failed)
    if ! helm list -n "$NAMESPACE" -q | grep -q "^${release_name}$"; then
        echo "Warning: Helm release '$release_name' does not exist. Skipping ConfigMap creation."
        echo "  The ConfigMap will be created by Helm when the release is installed."
        return 0
    fi
    
    # Check release status - skip if failed
    local release_status=$(helm status "$release_name" -n "$NAMESPACE" -o json 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "")
    if [ "$release_status" = "failed" ]; then
        echo "Warning: Helm release '$release_name' is in failed state. Skipping ConfigMap update."
        echo "  Please fix the release first, then rerun this script."
        return 0
    fi
    
    # If ConfigMap exists but release doesn't own it, delete it first to avoid managedFields conflict
    if kubectl get configmap "$cm_name" -n "$NAMESPACE" &>/dev/null; then
        local current_owner=$(kubectl get configmap "$cm_name" -n "$NAMESPACE" -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}' 2>/dev/null || echo "")
        if [ -n "$current_owner" ] && [ "$current_owner" != "$release_name" ]; then
            echo "Warning: ConfigMap '$cm_name' is owned by release '$current_owner', not '$release_name'."
            echo "  Deleting ConfigMap to avoid conflicts..."
            kubectl delete configmap "$cm_name" -n "$NAMESPACE" --ignore-not-found=true
        fi
    fi
    
    # Create or update ConfigMap with schema files
    kubectl create configmap "$cm_name" \
        --from-file=. \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Helm labels and annotations
    kubectl label configmap "$cm_name" \
        -n "$NAMESPACE" \
        --overwrite \
        app.kubernetes.io/managed-by=Helm \
        app.kubernetes.io/instance="$release_name" \
        app.kubernetes.io/name=onix-kafka \
        app.kubernetes.io/version=latest \
        helm.sh/chart=onix-kafka-0.1.0
    
    kubectl annotate configmap "$cm_name" \
        -n "$NAMESPACE" \
        --overwrite \
        meta.helm.sh/release-name="$release_name" \
        meta.helm.sh/release-namespace="$NAMESPACE"
}

create_or_update_configmap "$BAP_CONFIGMAP" "$RELEASE_BAP"
cd "$SCRIPT_DIR"  # Return to original directory

# Create or update BPP schemas ConfigMap
BPP_CONFIGMAP="${RELEASE_BPP}-onix-kafka-schemas"
echo "Creating/updating $BPP_CONFIGMAP ConfigMap..."
cd "$SCHEMAS_DIR"
create_or_update_configmap "$BPP_CONFIGMAP" "$RELEASE_BPP"
cd "$SCRIPT_DIR"  # Return to original directory

echo "Schemas ConfigMap populated successfully!"
echo ""
echo "To apply the changes, restart the pods:"
echo "  kubectl delete pod -n $NAMESPACE -l component=bap,app.kubernetes.io/instance=$RELEASE_BAP"
echo "  kubectl delete pod -n $NAMESPACE -l component=bpp,app.kubernetes.io/instance=$RELEASE_BPP"

