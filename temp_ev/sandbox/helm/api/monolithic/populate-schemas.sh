#!/bin/bash
# Script to populate schemas ConfigMap for BAP and BPP monolithic deployments

set -e

NAMESPACE="${NAMESPACE:-ev-charging-sandbox}"
SCHEMAS_DIR="${SCHEMAS_DIR:-../../../../schemas/beckn.one_deg_ev-charging/v2.0.0}"
RELEASE_BAP="${RELEASE_BAP:-ev-charging-bap}"
RELEASE_BPP="${RELEASE_BPP:-ev-charging-bpp}"

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
BAP_CONFIGMAP="${RELEASE_BAP}-onix-api-monolithic-schemas"
echo "Creating/updating $BAP_CONFIGMAP ConfigMap..."
kubectl create configmap "$BAP_CONFIGMAP" \
    --from-file="$SCHEMAS_DIR" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create or update BPP schemas ConfigMap
BPP_CONFIGMAP="${RELEASE_BPP}-onix-api-monolithic-schemas"
echo "Creating/updating $BPP_CONFIGMAP ConfigMap..."
kubectl create configmap "$BPP_CONFIGMAP" \
    --from-file="$SCHEMAS_DIR" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Schemas ConfigMap populated successfully!"
echo ""
echo "To apply the changes, restart the pods:"
echo "  kubectl delete pod -n $NAMESPACE -l component=bap,app.kubernetes.io/instance=$RELEASE_BAP"
echo "  kubectl delete pod -n $NAMESPACE -l component=bpp,app.kubernetes.io/instance=$RELEASE_BPP"

