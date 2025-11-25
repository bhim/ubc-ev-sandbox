#!/bin/bash

# Common functions for publishing messages to RabbitMQ

RABBITMQ_HOST="${RABBITMQ_HOST:-localhost}"
RABBITMQ_PORT="${RABBITMQ_PORT:-15672}"
RABBITMQ_USER="${RABBITMQ_USER:-guest}"
RABBITMQ_PASS="${RABBITMQ_PASS:-guest}"
EXCHANGE="${EXCHANGE:-beckn_exchange}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Function to publish a message
publish_message() {
  local routing_key=$1
  local json_file=$2
  local description=$3
  
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
  
  # Generate unique IDs
  local transaction_id=$(generate_uuid)
  local message_id=$(generate_uuid)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Update JSON with dynamic values
  local message=$(jq \
    --arg tid "$transaction_id" \
    --arg mid "$message_id" \
    --arg ts "$timestamp" \
    '.context.transaction_id = $tid | .context.message_id = $mid | .context.timestamp = $ts' \
    "$json_file")
  
  echo -e "${YELLOW}Publishing: $description${NC}"
  echo "  Routing Key: $routing_key"
  echo "  Transaction ID: $transaction_id"
  echo "  Message ID: $message_id"
  
  # Build the request JSON with payload as a string
  # First, get the compact JSON, then convert it to a JSON string using jq -Rs
  local compact_json=$(echo "$message" | jq -c .)
  local payload_string=$(echo "$compact_json" | jq -Rs .)
  
  # Build the request JSON, using the payload string directly
  local request_json=$(jq -n \
    --arg routing_key "$routing_key" \
    --argjson payload "$payload_string" \
    '{
      "properties": {},
      "routing_key": $routing_key,
      "payload": $payload,
      "payload_encoding": "string"
    }')
  
  local response=$(curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
    -H "Content-Type: application/json" \
    -X POST \
    "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/exchanges/%2F/${EXCHANGE}/publish" \
    -d "$request_json")
  
  if echo "$response" | grep -q '"routed":true'; then
    echo -e "${GREEN}  ✓ Published successfully!${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}  ✗ Failed to publish${NC}"
    echo "  Response: $response"
    echo ""
    return 1
  fi
}

