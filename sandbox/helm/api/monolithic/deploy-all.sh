#!/bin/bash

# Deploy All Services Script
# This script deploys all services for the EV Charging sandbox environment
# It can be run from any directory

set -e  # Exit on error

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"

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
if [ ! -d "${PROJECT_ROOT}/helm/api/monolithic" ]; then
  echo -e "${RED}Error: Helm chart not found at ${PROJECT_ROOT}/helm/api/monolithic${NC}"
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/values-sandbox.yaml" ]; then
  echo -e "${RED}Error: values-sandbox.yaml not found at ${SCRIPT_DIR}/values-sandbox.yaml${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Paths verified${NC}"
echo ""

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace ev-charging-sandbox --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"
echo ""

# Deploy BAP adapter
echo -e "${YELLOW}Deploying BAP adapter...${NC}"
helm upgrade --install ev-charging-bap ${PROJECT_ROOT}/helm/api/monolithic \
  -f ${PROJECT_ROOT}/helm/api/monolithic/values-bap.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace
echo -e "${GREEN}✓ BAP adapter deployed${NC}"
echo ""

# Deploy BPP adapter
echo -e "${YELLOW}Deploying BPP adapter...${NC}"
helm upgrade --install ev-charging-bpp ${PROJECT_ROOT}/helm/api/monolithic \
  -f ${PROJECT_ROOT}/helm/api/monolithic/values-bpp.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ BPP adapter deployed${NC}"
echo ""

# Deploy Mock Registry
echo -e "${YELLOW}Deploying Mock Registry...${NC}"
helm upgrade --install mock-registry ${PROJECT_ROOT}/sandbox/mock-registry \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ Mock Registry deployed${NC}"
echo ""

# Deploy Mock CDS
echo -e "${YELLOW}Deploying Mock CDS...${NC}"
helm upgrade --install mock-cds ${PROJECT_ROOT}/sandbox/mock-cds \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ Mock CDS deployed${NC}"
echo ""

# Deploy Mock BAP
echo -e "${YELLOW}Deploying Mock BAP...${NC}"
helm upgrade --install mock-bap ${PROJECT_ROOT}/sandbox/mock-bap \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ Mock BAP deployed${NC}"
echo ""

# Deploy Mock BPP
echo -e "${YELLOW}Deploying Mock BPP...${NC}"
helm upgrade --install mock-bpp ${PROJECT_ROOT}/sandbox/mock-bpp \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ Mock BPP deployed${NC}"
echo ""

# Populate schemas
echo -e "${YELLOW}Populating schemas...${NC}"
if [ -f "${SCRIPT_DIR}/populate-schemas.sh" ]; then
  cd "${SCRIPT_DIR}"
  ./populate-schemas.sh
  echo -e "${GREEN}✓ Schemas populated${NC}"
else
  echo -e "${YELLOW}⚠ populate-schemas.sh not found, skipping schema population${NC}"
fi
echo ""

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

