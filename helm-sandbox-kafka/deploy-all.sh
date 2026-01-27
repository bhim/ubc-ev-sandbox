#!/bin/bash

# Deploy All Services Script for Kafka Sandbox
# This script deploys all services for the EV Charging Kafka sandbox environment
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
echo -e "${YELLOW}Deploying EV Charging Kafka Sandbox - All Services${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Project Root: ${PROJECT_ROOT}"
echo "Namespace: ev-charging-sandbox"
echo ""

# Verify paths exist
echo -e "${YELLOW}Verifying paths...${NC}"
if [ ! -d "${PROJECT_ROOT}/helm-kafka" ]; then
  echo -e "${RED}Error: Helm chart not found at ${PROJECT_ROOT}/helm-kafka${NC}"
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
    echo -e "${GREEN}✓ Deployment ${deployment_name} restarted${NC}"
  fi
}

# Deploy BAP adapter
echo -e "${YELLOW}Deploying BAP adapter...${NC}"
helm upgrade --install onix-bap ${PROJECT_ROOT}/helm-kafka \
  -f ${PROJECT_ROOT}/helm-kafka/values-bap.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix \
  --namespace ev-charging-sandbox \
  --create-namespace
echo -e "${GREEN}✓ BAP adapter deployed${NC}"
# Force restart to ensure new pods are created
restart_deployment "onix-bap"
restart_deployment "onix-kafka"
restart_deployment "onix-kafka-ui"
restart_deployment "onix-redis-bap"
echo ""

# Deploy BPP adapter
echo -e "${YELLOW}Deploying BPP adapter...${NC}"
helm upgrade --install onix-bpp ${PROJECT_ROOT}/helm-kafka \
  -f ${PROJECT_ROOT}/helm-kafka/values-bpp.yaml \
  -f ${SCRIPT_DIR}/values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix \
  --namespace ev-charging-sandbox
echo -e "${GREEN}✓ BPP adapter deployed${NC}"
# Force restart to ensure new pods are created
restart_deployment "onix-bpp"
restart_deployment "onix-redis-bpp"
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
    --set fullnameOverride=mock-cds \
    --namespace ev-charging-sandbox
  echo -e "${GREEN}✓ Mock CDS deployed${NC}"
  restart_deployment "mock-cds"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock CDS Helm chart not found at ${PROJECT_ROOT}/mock/mock-cds${NC}"
  echo ""
fi

# Deploy Mock BAP Kafka
if [ -d "${PROJECT_ROOT}/mock/mock-bap-kafka" ]; then
  echo -e "${YELLOW}Deploying Mock BAP Kafka...${NC}"
  helm upgrade --install mock-bap-kafka ${PROJECT_ROOT}/mock/mock-bap-kafka \
    --namespace ev-charging-sandbox \
    --wait
  echo -e "${GREEN}✓ Mock BAP Kafka deployed${NC}"
  restart_deployment "mock-bap-kafka"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock BAP Kafka Helm chart not found at ${PROJECT_ROOT}/mock/mock-bap-kafka${NC}"
  echo ""
fi

# Deploy Mock BPP Kafka
if [ -d "${PROJECT_ROOT}/mock/mock-bpp-kafka" ]; then
  echo -e "${YELLOW}Deploying Mock BPP Kafka...${NC}"
  helm upgrade --install mock-bpp-kafka ${PROJECT_ROOT}/mock/mock-bpp-kafka \
    --namespace ev-charging-sandbox \
    --wait
  echo -e "${GREEN}✓ Mock BPP Kafka deployed${NC}"
  restart_deployment "mock-bpp-kafka"
  echo ""
else
  echo -e "${YELLOW}⚠ Mock BPP Kafka Helm chart not found at ${PROJECT_ROOT}/mock/mock-bpp-kafka${NC}"
  echo ""
fi

# Function to setup port forwarding
setup_port_forwards() {
  echo -e "${YELLOW}Setting up port forwarding...${NC}"
  
  # Kill any existing port forwards for these services
  pkill -f "kubectl port-forward.*onix-bap" || true
  pkill -f "kubectl port-forward.*onix-bpp" || true
  pkill -f "kubectl port-forward.*onix-kafka-ui" || true
  
  # Wait a moment for processes to terminate
  sleep 1
  
  # Start port forwards in background
  echo -e "${YELLOW}Forwarding BAP ONIX Plugin (port 8001)...${NC}"
  kubectl port-forward -n ev-charging-sandbox svc/onix-bap 8001:8001 > /dev/null 2>&1 &
  BAP_PF_PID=$!
  
  echo -e "${YELLOW}Forwarding BPP ONIX Plugin (port 8002)...${NC}"
  kubectl port-forward -n ev-charging-sandbox svc/onix-bpp 8002:8002 > /dev/null 2>&1 &
  BPP_PF_PID=$!
  
  echo -e "${YELLOW}Forwarding Kafka UI (port 8080)...${NC}"
  kubectl port-forward -n ev-charging-sandbox svc/onix-kafka-ui 8080:8080 > /dev/null 2>&1 &
  KAFKA_UI_PF_PID=$!
  
  sleep 2
  
  # Check if port forwards are running
  if kill -0 $BAP_PF_PID 2>/dev/null && kill -0 $BPP_PF_PID 2>/dev/null && kill -0 $KAFKA_UI_PF_PID 2>/dev/null; then
    echo -e "${GREEN}✓ Port forwarding active${NC}"
    echo ""
    echo "Services available at:"
    echo "  - BAP ONIX Plugin:    http://localhost:8001"
    echo "    - Receiver:          http://localhost:8001/bap/receiver/{action}"
    echo "    - Health:           http://localhost:8001/health"
    echo ""
    echo "  - BPP ONIX Plugin:    http://localhost:8002"
    echo "    - Receiver:         http://localhost:8002/bpp/receiver/{action}"
    echo "    - Health:           http://localhost:8002/health"
    echo ""
    echo "  - Kafka UI:           http://localhost:8080"
    echo ""
    echo -e "${YELLOW}Note:${NC} Port forwards are running in background. To stop them:"
    echo "  pkill -f 'kubectl port-forward.*onix'"
    echo ""
  else
    echo -e "${RED}⚠ Some port forwards may have failed. Check manually:${NC}"
    echo "  kubectl port-forward -n ev-charging-sandbox svc/onix-bap 8001:8001"
    echo "  kubectl port-forward -n ev-charging-sandbox svc/onix-bpp 8002:8002"
    echo "  kubectl port-forward -n ev-charging-sandbox svc/onix-kafka-ui 8080:8080"
    echo ""
  fi
}

# Setup port forwarding
setup_port_forwards

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
echo "Port forwarding is active! Services:"
echo "  - BAP ONIX Plugin:    http://localhost:8001"
echo "  - BPP ONIX Plugin:    http://localhost:8002"
echo "  - Kafka UI:           http://localhost:8080"
echo ""
echo "To stop port forwards:"
echo "  pkill -f 'kubectl port-forward.*onix'"
echo ""
echo "Or use the port-forward script for interactive management:"
echo "  ./port-forward.sh"
echo ""

