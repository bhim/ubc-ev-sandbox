#!/bin/bash

# Common functions for publishing messages to Kafka

KAFKA_HOST="${KAFKA_HOST:-localhost}"
KAFKA_PORT="${KAFKA_PORT:-9092}"
KAFKA_BOOTSTRAP="${KAFKA_BOOTSTRAP:-${KAFKA_HOST}:${KAFKA_PORT}}"

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

# Function to ensure topic exists, create if it doesn't
ensure_topic_exists() {
  local topic=$1
  
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
  
  # Check if we're running inside Docker or have kafka-console-producer available
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
    echo "Either run this script from a machine with Kafka CLI tools installed,"
    echo "or ensure the Kafka container is running: docker ps | grep kafka"
    return 1
  fi
}

