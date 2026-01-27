#!/bin/bash

# Common functions for publishing messages to Kafka

KAFKA_HOST="${KAFKA_HOST:-localhost}"
KAFKA_PORT="${KAFKA_PORT:-9092}"
KAFKA_BOOTSTRAP="${KAFKA_BOOTSTRAP:-${KAFKA_HOST}:${KAFKA_PORT}}"
KAFKA_NAMESPACE="${KAFKA_NAMESPACE:-ev-charging-sandbox}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to find Kafka pod in Kubernetes
find_kafka_pod() {
  if ! command -v kubectl &> /dev/null; then
    return 1
  fi
  
  # Try multiple label selectors to find Kafka pod
  local kafka_pod=$(kubectl get pod -n "$KAFKA_NAMESPACE" -l component=kafka --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  # If not found, try app=kafka
  if [ -z "$kafka_pod" ]; then
    kafka_pod=$(kubectl get pod -n "$KAFKA_NAMESPACE" -l app=kafka --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  fi
  
  # If still not found, try to find any pod with "kafka" in the name
  if [ -z "$kafka_pod" ]; then
    kafka_pod=$(kubectl get pod -n "$KAFKA_NAMESPACE" --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -i kafka | head -n 1)
  fi
  
  if [ -n "$kafka_pod" ]; then
    echo "$kafka_pod"
    return 0
  fi
  
  return 1
}

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

# Function to ensure topic exists, create if it doesn't
ensure_topic_exists() {
  local topic=$1
  
  # Try Docker first (for docker-compose setups)
  if docker ps | grep -q kafka; then
    # Check if topic exists
    docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null | grep -q "^${topic}$"
    
    if [ $? -ne 0 ]; then
      # Topic doesn't exist, create it
      echo -e "${YELLOW}  Creating topic: ${topic}${NC}"
      docker exec kafka kafka-topics --create \
        --bootstrap-server localhost:9092 \
        --topic "${topic}" \
        --partitions 1 \
        --replication-factor 1 \
        --if-not-exists 2>&1
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ Topic created: ${topic}${NC}"
        return 0
      else
        echo -e "${RED}  ✗ Failed to create topic: ${topic}${NC}"
        return 1
      fi
    fi
    return 0
  # Try Kubernetes/kubectl (for Helm/Kubernetes setups)
  elif command -v kubectl &> /dev/null; then
    local kafka_pod=$(find_kafka_pod)
    if [ -n "$kafka_pod" ]; then
      # Check if topic exists
      kubectl exec -n "$KAFKA_NAMESPACE" "$kafka_pod" -- kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null | grep -q "^${topic}$"
      
      if [ $? -ne 0 ]; then
        # Topic doesn't exist, create it
        echo -e "${YELLOW}  Creating topic: ${topic}${NC}"
        kubectl exec -n "$KAFKA_NAMESPACE" "$kafka_pod" -- kafka-topics --create \
          --bootstrap-server localhost:9092 \
          --topic "${topic}" \
          --partitions 1 \
          --replication-factor 1 \
          --if-not-exists 2>&1
        
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}  ✓ Topic created: ${topic}${NC}"
          return 0
        else
          echo -e "${RED}  ✗ Failed to create topic: ${topic}${NC}"
          return 1
        fi
      fi
      return 0
    fi
  # Try local Kafka CLI tools
  elif command -v kafka-topics &> /dev/null || command -v kafka-topics.sh &> /dev/null; then
    # Check if topic exists using local kafka-topics
    local kafka_cmd="kafka-topics"
    if ! command -v kafka-topics &> /dev/null; then
      kafka_cmd="kafka-topics.sh"
    fi
    $kafka_cmd --list --bootstrap-server "$KAFKA_BOOTSTRAP" 2>/dev/null | grep -q "^${topic}$"
    
    if [ $? -ne 0 ]; then
      # Topic doesn't exist, create it
      echo -e "${YELLOW}  Creating topic: ${topic}${NC}"
      $kafka_cmd --create \
        --bootstrap-server "$KAFKA_BOOTSTRAP" \
        --topic "$topic" \
        --partitions 1 \
        --replication-factor 1 \
        --if-not-exists 2>&1
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ Topic created: ${topic}${NC}"
        return 0
      else
        echo -e "${RED}  ✗ Failed to create topic: ${topic}${NC}"
        return 1
      fi
    fi
    return 0
  else
    # Can't check/create topics, but continue anyway (Kafka might auto-create)
    return 0
  fi
}

# Function to publish a message to Kafka
publish_message() {
  local topic=$1
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
  echo "  Topic: $topic"
  echo "  Transaction ID: $transaction_id"
  echo "  Message ID: $message_id"
  
  # Ensure topic exists before publishing
  if ! ensure_topic_exists "$topic"; then
    echo -e "${RED}  ✗ Failed to ensure topic exists${NC}"
    echo ""
    return 1
  fi
  
  # Try Docker first (for docker-compose setups)
  if docker ps | grep -q kafka; then
    # Use docker exec to run kafka-console-producer
    local compact_json=$(echo "$message" | jq -c .)
    local error_output=$(mktemp)
    echo "$compact_json" | docker exec -i kafka kafka-console-producer \
      --bootstrap-server localhost:9092 \
      --topic "$topic" \
      2> "$error_output"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
      echo -e "${GREEN}  ✓ Published successfully!${NC}"
      echo ""
      rm -f "$error_output"
      return 0
    else
      echo -e "${RED}  ✗ Failed to publish${NC}"
      if [ -s "$error_output" ]; then
        echo -e "${RED}  Error details:${NC}"
        cat "$error_output" | sed 's/^/    /'
      fi
      echo ""
      rm -f "$error_output"
      return 1
    fi
  # Try Kubernetes/kubectl (for Helm/Kubernetes setups)
  elif command -v kubectl &> /dev/null; then
    local kafka_pod=$(find_kafka_pod)
    if [ -n "$kafka_pod" ]; then
      # Use kubectl exec to run kafka-console-producer
      local compact_json=$(echo "$message" | jq -c .)
      local error_output=$(mktemp)
      echo "$compact_json" | kubectl exec -i -n "$KAFKA_NAMESPACE" "$kafka_pod" -- kafka-console-producer \
        --bootstrap-server localhost:9092 \
        --topic "$topic" \
        2> "$error_output"
      local exit_code=$?
      
      if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}  ✓ Published successfully!${NC}"
        echo ""
        rm -f "$error_output"
        return 0
      else
        echo -e "${RED}  ✗ Failed to publish${NC}"
        if [ -s "$error_output" ]; then
          echo -e "${RED}  Error details:${NC}"
          cat "$error_output" | sed 's/^/    /'
        fi
        echo ""
        rm -f "$error_output"
        return 1
      fi
    else
      echo -e "${YELLOW}Warning: Kafka pod not found in namespace '${KAFKA_NAMESPACE}'.${NC}"
      echo "Trying local Kafka CLI tools or Docker as fallback..."
      # Fall through to try local tools or Docker
    fi
  # Try local Kafka CLI tools
  elif command -v kafka-console-producer &> /dev/null || command -v kafka-console-producer.sh &> /dev/null; then
    # Use local kafka-console-producer
    local compact_json=$(echo "$message" | jq -c .)
    local error_output=$(mktemp)
    local kafka_prod_cmd="kafka-console-producer"
    if ! command -v kafka-console-producer &> /dev/null; then
      kafka_prod_cmd="kafka-console-producer.sh"
    fi
    echo "$compact_json" | $kafka_prod_cmd \
      --bootstrap-server "$KAFKA_BOOTSTRAP" \
      --topic "$topic" \
      2> "$error_output"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
      echo -e "${GREEN}  ✓ Published successfully!${NC}"
      echo ""
      rm -f "$error_output"
      return 0
    else
      echo -e "${RED}  ✗ Failed to publish${NC}"
      if [ -s "$error_output" ]; then
        echo -e "${RED}  Error details:${NC}"
        cat "$error_output" | sed 's/^/    /'
      fi
      echo ""
      rm -f "$error_output"
      return 1
    fi
  else
    echo -e "${RED}Error: Kafka producer not available.${NC}"
    echo "Options:"
    echo "  1. Docker: Ensure Kafka container is running: docker ps | grep kafka"
    echo "  2. Kubernetes: Ensure kubectl is configured and Kafka pod is running: kubectl get pods -n ${KAFKA_NAMESPACE}"
    echo "  3. Local: Install Kafka CLI tools (kafka-console-producer)"
    echo ""
    echo "You can set KAFKA_NAMESPACE environment variable to specify namespace (default: ev-charging-sandbox)"
    return 1
  fi
}

