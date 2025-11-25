#!/bin/bash

# Common functions for publishing messages to RabbitMQ

RABBITMQ_HOST="${RABBITMQ_HOST:-rabbitmq}"
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
  local MAX_RETRIES=3
  local retry_count=0
  
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
  # Get the compact JSON - this will be used as the payload string
  local compact_json=$(echo "$message" | jq -c .)
  
  # Build the request JSON
  # Use --arg to pass the payload as a string (jq will JSON-encode it)
  local request_json=$(jq -n \
    --arg routing_key "$routing_key" \
    --arg payload "$compact_json" \
    '{
      "properties": {},
      "routing_key": $routing_key,
      "payload": $payload,
      "payload_encoding": "string"
    }')
  
  # Retry loop
  while [ $retry_count -lt $MAX_RETRIES ]; do
    retry_count=$((retry_count + 1))
    local http_code
    local response
    response=$(curl -s -w "\n%{http_code}" -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
      -H "Content-Type: application/json" \
      -X POST \
      "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/exchanges/%2F/${EXCHANGE}/publish" \
      -d "$request_json")
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] && echo "$response" | grep -q '"routed":true'; then
      echo -e "${GREEN}  ✓ Published successfully!${NC}"
      echo ""
      return 0
    else
      if [ $retry_count -lt $MAX_RETRIES ]; then
        echo -e "${YELLOW}  ⚠ Failed to publish (attempt $retry_count/$MAX_RETRIES), retrying...${NC}"
        if [ -n "$response" ]; then
          echo "  Response: $response"
        fi
        if [ -n "$http_code" ] && [ "$http_code" != "200" ]; then
          echo "  HTTP Code: $http_code"
        fi
        sleep 1
      else
        echo -e "${RED}  ✗ Failed to publish after $MAX_RETRIES attempts${NC}"
        if [ -n "$http_code" ] && [ "$http_code" != "200" ]; then
          echo "  HTTP Code: $http_code"
        fi
        if [ -n "$response" ]; then
          echo "  Response: $response"
        else
          echo "  Response: (empty or connection failed)"
        fi
        echo ""
        return 1
      fi
    fi
  done
  
  # Should never reach here, but just in case
  return 1
}

