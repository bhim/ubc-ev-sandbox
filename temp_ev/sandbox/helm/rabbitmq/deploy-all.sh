#!/bin/bash

# Deploy All Services Script for RabbitMQ Sandbox
# This script deploys all services for the EV Charging RabbitMQ sandbox environment
# It can be run from any directory

# Don't exit on error - continue deploying other services even if one fails
set +e

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# From sandbox/helm/rabbitmq, go up 3 levels to reach project root (ev_charging_sandbox)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Deploying EV Charging RabbitMQ Sandbox - All Services${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Project Root: ${PROJECT_ROOT}"
echo "Namespace: ev-charging-sandbox"
echo ""

# Verify paths exist
echo -e "${YELLOW}Verifying paths...${NC}"
if [ ! -d "${PROJECT_ROOT}/helm/rabbitmq" ]; then
  echo -e "${RED}Error: Helm chart not found at ${PROJECT_ROOT}/helm/rabbitmq${NC}"
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

# Deploy BAP adapter (includes RabbitMQ and Redis)
echo -e "${YELLOW}Deploying BAP adapter (with RabbitMQ and Redis)...${NC}"
# Delete ConfigMap if it exists to avoid conflicts (will be recreated by Helm)
kubectl delete configmap ev-charging-rabbitmq-bap-onix-rabbitmq-bap-config -n ev-charging-sandbox --ignore-not-found=true 2>/dev/null
if helm upgrade --install ev-charging-rabbitmq-bap ${PROJECT_ROOT}/helm/rabbitmq \
  -f ${PROJECT_ROOT}/helm/rabbitmq/values-bap.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace; then
  echo -e "${GREEN}✓ BAP adapter deployed${NC}"
else
  echo -e "${RED}✗ BAP adapter deployment failed${NC}"
  echo "  Check the error above and fix any issues before continuing"
fi
echo ""

# Deploy BPP adapter (includes RabbitMQ and Redis)
echo -e "${YELLOW}Deploying BPP adapter (with RabbitMQ and Redis)...${NC}"
# Delete ConfigMap if it exists to avoid conflicts (will be recreated by Helm)
kubectl delete configmap ev-charging-rabbitmq-bpp-onix-rabbitmq-bpp-config -n ev-charging-sandbox --ignore-not-found=true 2>/dev/null
if helm upgrade --install ev-charging-rabbitmq-bpp ${PROJECT_ROOT}/helm/rabbitmq \
  -f ${PROJECT_ROOT}/helm/rabbitmq/values-bpp.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox; then
  echo -e "${GREEN}✓ BPP adapter deployed${NC}"
else
  echo -e "${RED}✗ BPP adapter deployment failed${NC}"
  echo "  Check the error above and fix any issues before continuing"
fi
echo ""

# Deploy Mock Services for BAP (Registry, CDS, Mock BAP RabbitMQ)
echo -e "${YELLOW}Deploying Mock Services (BAP components)...${NC}"
if helm upgrade --install ev-charging-rabbitmq-sandbox-bap ${SCRIPT_DIR} \
  -f ${SCRIPT_DIR}/values.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox; then
  echo -e "${GREEN}✓ Mock services (BAP) deployed${NC}"
else
  echo -e "${RED}✗ Mock services (BAP) deployment failed${NC}"
  echo "  Check the error above and fix any issues before continuing"
fi
echo ""

# Deploy Mock Services for BPP (Mock BPP RabbitMQ)
echo -e "${YELLOW}Deploying Mock Services (BPP components)...${NC}"
if helm upgrade --install ev-charging-rabbitmq-sandbox-bpp ${SCRIPT_DIR} \
  -f ${SCRIPT_DIR}/values.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox; then
  echo -e "${GREEN}✓ Mock services (BPP) deployed${NC}"
else
  echo -e "${RED}✗ Mock services (BPP) deployment failed${NC}"
  echo "  Check the error above and fix any issues before continuing"
fi
echo ""

# Note: RabbitMQ and Redis are deployed with BAP/BPP adapters
echo -e "${YELLOW}Note:${NC} RabbitMQ and Redis are deployed as part of the BAP/BPP adapter charts."
echo "Mock services are deployed via the sandbox chart."
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
echo "Access RabbitMQ Management UI (after port forwarding):"
echo "  kubectl port-forward svc/ev-charging-rabbitmq-bap-onix-rabbitmq-rabbitmq 15672:15672 -n ev-charging-sandbox"
echo "  Then open: http://localhost:15672 (admin/admin)"
echo ""

