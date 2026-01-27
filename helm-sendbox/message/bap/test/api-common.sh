#!/bin/bash

# Common functions for API testing with curl

# Default configuration
BAP_URL="${BAP_URL:-http://localhost:8001}"
BPP_URL="${BPP_URL:-http://localhost:8002}"
NAMESPACE="${NAMESPACE:-ev-charging-sandbox}"

# Kubernetes service names (defaults)
BAP_SERVICE="${BAP_SERVICE:-onix-bap-service}"
BPP_SERVICE="${BPP_SERVICE:-onix-bpp-service}"
MOCK_BAP_SERVICE="${MOCK_BAP_SERVICE:-mock-bap}"
MOCK_BPP_SERVICE="${MOCK_BPP_SERVICE:-mock-bpp}"
MOCK_CDS_SERVICE="${MOCK_CDS_SERVICE:-mock-cds}"
MOCK_REGISTRY_SERVICE="${MOCK_REGISTRY_SERVICE:-mock-registry}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to generate UUID
generate_uuid() {
  if command -v uuidgen &> /dev/null; then
    uuidgen
  elif command -v python3 &> /dev/null; then
    python3 -c "import uuid; print(uuid.uuid4())"
  else
    # Fallback: simple UUID-like string
    cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/'
  fi
}

# Function to check if service is accessible
check_service() {
  local url=$1
  local service_name=$2
  
  if curl -s -f -o /dev/null "$url/health" 2>/dev/null; then
    return 0
  else
    echo -e "${YELLOW}Warning: Service $service_name may not be accessible at $url${NC}"
    echo -e "${YELLOW}  Make sure to port-forward or use LoadBalancer/NodePort${NC}"
    return 1
  fi
}

# Function to send API request
send_api_request() {
  local endpoint=$1
  local json_file=$2
  local description=$3
  local service_type=${4:-bap}  # bap or bpp
  
  if [ ! -f "$json_file" ]; then
    echo -e "${RED}✗ File not found: $json_file${NC}"
    return 1
  fi
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
    return 1
  fi
  
  # Determine base URL
  local base_url
  if [ "$service_type" = "bpp" ]; then
    base_url="$BPP_URL"
  else
    base_url="$BAP_URL"
  fi
  
  # Generate unique IDs
  local transaction_id=$(generate_uuid)
  local message_id=$(generate_uuid)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Update JSON with dynamic values and Kubernetes service names
  local message=$(jq \
    --arg tid "$transaction_id" \
    --arg mid "$message_id" \
    --arg ts "$timestamp" \
    --arg bap_uri "http://${BAP_SERVICE}:8001/bap/receiver" \
    --arg bpp_uri "http://${BPP_SERVICE}:8002/bpp/receiver" \
    '.context.transaction_id = $tid | 
     .context.message_id = $mid | 
     .context.timestamp = $ts |
     (.context.bap_uri = $bap_uri) |
     (if .context.bpp_uri then .context.bpp_uri = $bpp_uri else . end)' \
    "$json_file")
  
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Testing: ${description:-$endpoint}${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "  Endpoint: ${base_url}${endpoint}"
  echo "  Transaction ID: $transaction_id"
  echo "  Message ID: $message_id"
  echo ""
  
  # Send request
  local response=$(echo "$message" | curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    "${base_url}${endpoint}" \
    -d @-)
  
  local http_code=$(echo "$response" | tail -n1)
  local body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    echo -e "${GREEN}  ✓ Request successful (HTTP $http_code)${NC}"
    if [ ! -z "$body" ]; then
      echo -e "${GREEN}  Response:${NC}"
      echo "$body" | jq . 2>/dev/null || echo "$body" | head -c 200
      echo ""
    fi
    echo ""
    return 0
  else
    echo -e "${RED}  ✗ Request failed (HTTP $http_code)${NC}"
    if [ ! -z "$body" ]; then
      echo -e "${RED}  Error response:${NC}"
      echo "$body" | jq . 2>/dev/null || echo "$body" | head -c 500
      echo ""
    fi
    echo ""
    return 1
  fi
}

