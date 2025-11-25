#!/bin/bash

# Deploy All Services Script for Kafka Sandbox
# This script deploys all services for the EV Charging Kafka sandbox environment
# It can be run from any directory

# Don't exit on error - continue deploying other services even if one fails
set +e

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# From sandbox/helm/kafka, go up 3 levels to reach project root (ev_charging_sandbox)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Deploying EV Charging Kafka Sandbox - All Services${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Project Root: ${PROJECT_ROOT}"
echo "Namespace: ev-charging-sandbox"
echo ""

# Verify paths exist
echo -e "${YELLOW}Verifying paths...${NC}"
if [ ! -d "${PROJECT_ROOT}/helm/kafka" ]; then
  echo -e "${RED}Error: Helm chart not found at ${PROJECT_ROOT}/helm/kafka${NC}"
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
if helm upgrade --install ev-charging-kafka-bap ${PROJECT_ROOT}/helm/kafka \
  -f ${PROJECT_ROOT}/helm/kafka/values-bap.yaml \
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

# Deploy BPP adapter
echo -e "${YELLOW}Deploying BPP adapter...${NC}"
if helm upgrade --install ev-charging-kafka-bpp ${PROJECT_ROOT}/helm/kafka \
  -f ${PROJECT_ROOT}/helm/kafka/values-bpp.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox; then
  echo -e "${GREEN}✓ BPP adapter deployed${NC}"
else
  echo -e "${RED}✗ BPP adapter deployment failed${NC}"
  echo "  Check the error above and fix any issues before continuing"
fi
echo ""

# Note: Mock Registry and Mock CDS are now deployed as part of the Kafka Helm chart
# via mock-services.yaml when mockServices.enabled=true and component=bap
# They are deployed with the ev-charging-kafka-bap release and will have ev-charging- prefix
# If you need to deploy them separately, uncomment the following:

# Deploy Mock Registry (optional - already included in mock-services.yaml)
# echo -e "${YELLOW}Deploying Mock Registry...${NC}"
# if helm upgrade --install ev-charging-mock-registry ${PROJECT_ROOT}/sandbox/mock-registry \
#   --namespace ev-charging-sandbox; then
#   echo -e "${GREEN}✓ Mock Registry deployed${NC}"
# else
#   echo -e "${RED}✗ Mock Registry deployment failed${NC}"
# fi
# echo ""

# Deploy Mock CDS (optional - already included in mock-services.yaml)
# echo -e "${YELLOW}Deploying Mock CDS...${NC}"
# if helm upgrade --install ev-charging-mock-cds ${PROJECT_ROOT}/sandbox/mock-cds \
#   --namespace ev-charging-sandbox; then
#   echo -e "${GREEN}✓ Mock CDS deployed${NC}"
# else
#   echo -e "${RED}✗ Mock CDS deployment failed${NC}"
# fi
# echo ""

# Note about mock Kafka services
echo -e "${YELLOW}Note:${NC} Mock BAP-Kafka and Mock BPP-Kafka services are configured via"
echo "values-sandbox.yaml and may be deployed as part of the Kafka Helm chart."
echo "If they need to be deployed separately, check the chart documentation."
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
echo "Access Kafka UI (after port forwarding):"
echo "  kubectl port-forward svc/kafka-ui 8080:8080 -n ev-charging-sandbox"
echo "  Then open: http://localhost:8080"
echo ""

