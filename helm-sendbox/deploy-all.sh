#!/bin/bash

# Deploy All Services Script
# This script deploys all services for the EV Charging sandbox environment
# It can be run from any directory

set -e  # Exit on error

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Deploying EV Charging Sandbox - All Services${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Project Root: ${PROJECT_ROOT}"
echo "Namespace: ev-charging-sandbox"
echo ""

# Verify paths exist
echo -e "${YELLOW}Verifying paths...${NC}"
if [ ! -d "${PROJECT_ROOT}/helm" ]; then
  echo -e "${RED}Error: Helm chart not found at ${PROJECT_ROOT}/helm${NC}"
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/values-sandbox.yaml" ]; then
  echo -e "${RED}Error: values-sandbox.yaml not found at ${SCRIPT_DIR}/values-sandbox.yaml${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Paths verified${NC}"
echo ""

# Check Kubernetes cluster connectivity
echo -e "${YELLOW}Checking Kubernetes cluster connectivity...${NC}"
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
  echo -e "${YELLOW}Please ensure your cluster is running and kubectl is configured correctly.${NC}"
  echo -e "${YELLOW}Try: kubectl cluster-info${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Cluster accessible${NC}"
echo ""

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace...${NC}"
set +e  # Temporarily disable exit on error for namespace check
kubectl get namespace ev-charging-sandbox &>/dev/null
NAMESPACE_EXISTS=$?
set -e  # Re-enable exit on error

if [ $NAMESPACE_EXISTS -ne 0 ]; then
  kubectl create namespace ev-charging-sandbox
else
  echo -e "${YELLOW}Namespace already exists${NC}"
fi
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

# Function to restart deployment to force pod recreation
restart_deployment() {
  local deployment_name=$1
  if kubectl get deployment "$deployment_name" -n ev-charging-sandbox &>/dev/null; then
    echo -e "${YELLOW}Restarting deployment: ${deployment_name}...${NC}"
    kubectl rollout restart deployment "$deployment_name" -n ev-charging-sandbox
    kubectl rollout status deployment "$deployment_name" -n ev-charging-sandbox --timeout=60s
    echo -e "${GREEN}✓ Deployment ${deployment_name} restarted${NC}"
  fi
}

# Deploy BAP adapter
echo -e "${YELLOW}Deploying BAP adapter...${NC}"
helm upgrade --install onix-bap ${PROJECT_ROOT}/helm \
  -f ${PROJECT_ROOT}/helm/values-bap.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace
echo -e "${GREEN}✓ BAP adapter deployed${NC}"
# Force restart to ensure new pods are created
restart_deployment "onix-bap-bap"
echo ""

# Deploy BPP adapter
echo -e "${YELLOW}Deploying BPP adapter...${NC}"
helm upgrade --install onix-bpp ${PROJECT_ROOT}/helm \
  -f ${PROJECT_ROOT}/helm/values-bpp.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ BPP adapter deployed${NC}"
# Force restart to ensure new pods are created
restart_deployment "onix-bpp-bpp"
echo ""

# Note: Mock services (mock-registry, mock-cds, mock-bap, mock-bpp) should be deployed
# separately using their own Helm charts from the mock/ directory.

# Deploy Mock Registry
if [ -d "${PROJECT_ROOT}/mock/mock-registry" ]; then
  echo -e "${YELLOW}Deploying Mock Registry...${NC}"
  helm upgrade --install mock-registry ${PROJECT_ROOT}/mock/mock-registry \
    --namespace ev-charging-sandbox \
    --wait
  echo -e "${GREEN}✓ Mock Registry deployed${NC}"
  restart_deployment "mock-registry"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock Registry Helm chart not found at ${PROJECT_ROOT}/mock/mock-registry${NC}"
  echo ""
fi

# Deploy Mock CDS
if [ -d "${PROJECT_ROOT}/mock/mock-cds" ]; then
  echo -e "${YELLOW}Deploying Mock CDS...${NC}"
  helm upgrade --install mock-cds ${PROJECT_ROOT}/mock/mock-cds \
    --namespace ev-charging-sandbox \
    --wait
  echo -e "${GREEN}✓ Mock CDS deployed${NC}"
  restart_deployment "mock-cds"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock CDS Helm chart not found at ${PROJECT_ROOT}/mock/mock-cds${NC}"
  echo ""
fi

# Deploy Mock BAP
if [ -d "${PROJECT_ROOT}/mock/mock-bap" ]; then
  echo -e "${YELLOW}Deploying Mock BAP...${NC}"
  helm upgrade --install mock-bap ${PROJECT_ROOT}/mock/mock-bap \
    --namespace ev-charging-sandbox \
    --wait
  echo -e "${GREEN}✓ Mock BAP deployed${NC}"
  restart_deployment "mock-bap"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock BAP Helm chart not found at ${PROJECT_ROOT}/mock/mock-bap${NC}"
  echo ""
fi

# Deploy Mock BPP
if [ -d "${PROJECT_ROOT}/mock/mock-bpp" ]; then
  echo -e "${YELLOW}Deploying Mock BPP...${NC}"
  helm upgrade --install mock-bpp ${PROJECT_ROOT}/mock/mock-bpp \
    --namespace ev-charging-sandbox \
    --wait
  echo -e "${GREEN}✓ Mock BPP deployed${NC}"
  restart_deployment "mock-bpp"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock BPP Helm chart not found at ${PROJECT_ROOT}/mock/mock-bpp${NC}"
  echo ""
fi

# Note: Schemas are automatically handled by the Helm chart via ConfigMap - no manual population needed

# Summary
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Check deployment status:"
echo "  kubectl get pods -n ev-charging-sandbox"
echo "  kubectl get svc -n ev-charging-sandbox"
echo ""
echo "Watch pod status:"
echo "  watch -n 2 'kubectl get pods -n ev-charging-sandbox'"
echo ""

