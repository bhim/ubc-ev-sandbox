#!/bin/bash
# Script to populate schemas ConfigMap for BAP and BPP microservice deployments

set -e

NAMESPACE="${NAMESPACE:-ev-charging-sandbox}"
SCHEMAS_BASE_DIR="${SCHEMAS_BASE_DIR:-../../../../schemas}"
SCHEMAS_SUBDIR="${SCHEMAS_SUBDIR:-beckn.one_deg_ev-charging/v2.0.0}"
RELEASE_BAP="${RELEASE_BAP:-ev-charging-bap}"
RELEASE_BPP="${RELEASE_BPP:-ev-charging-bpp}"

SCHEMAS_FULL_DIR="${SCHEMAS_BASE_DIR}/${SCHEMAS_SUBDIR}"

if [ ! -d "$SCHEMAS_FULL_DIR" ]; then
    echo "Error: Schemas directory not found: $SCHEMAS_FULL_DIR"
    echo "Please set SCHEMAS_BASE_DIR and SCHEMAS_SUBDIR environment variables to the correct paths"
    exit 1
fi

echo "Populating schemas ConfigMap from: $SCHEMAS_FULL_DIR"
echo "Namespace: $NAMESPACE"
echo "BAP Release: $RELEASE_BAP"
echo "BPP Release: $RELEASE_BPP"
echo "Note: Directory structure will be preserved as: $SCHEMAS_SUBDIR/"

# Create or update BAP schemas ConfigMap
# Note: Files are stored flat in ConfigMap; initContainer will organize them into proper directory structure
BAP_CONFIGMAP="${RELEASE_BAP}-onix-api-microservice-schemas"
echo "Creating/updating $BAP_CONFIGMAP ConfigMap..."
kubectl create configmap "$BAP_CONFIGMAP" \
    --from-file="${SCHEMAS_FULL_DIR}" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create or update BPP schemas ConfigMap
BPP_CONFIGMAP="${RELEASE_BPP}-onix-api-microservice-schemas"
echo "Creating/updating $BPP_CONFIGMAP ConfigMap..."
kubectl create configmap "$BPP_CONFIGMAP" \
    --from-file="${SCHEMAS_FULL_DIR}" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Schemas ConfigMap populated successfully!"
echo ""
echo "To apply the changes, restart the pods:"
echo "  kubectl delete pod -n $NAMESPACE -l component=bap,app.kubernetes.io/instance=$RELEASE_BAP"
echo "  kubectl delete pod -n $NAMESPACE -l component=bpp,app.kubernetes.io/instance=$RELEASE_BPP"

