#!/bin/bash

# Publish all BPP test messages to Kafka
# Usage: ./publish-all.sh [action]
# If action is provided, only publish that specific action's messages
# Examples:
#   ./publish-all.sh              # Publish all messages (all 12 message types)
#   ./publish-all.sh on_discover  # Publish only on_discover messages
#   ./publish-all.sh on_select    # Publish only on_select message
#   ./publish-all.sh on_init      # Publish only on_init message
#   ./publish-all.sh on_confirm   # Publish only on_confirm message
#   ./publish-all.sh on_status    # Publish only on_status message
#   ./publish-all.sh on_track     # Publish only on_track message
#   ./publish-all.sh on_cancel    # Publish only on_cancel message
#   ./publish-all.sh on_update    # Publish only on_update message
#   ./publish-all.sh on_rating    # Publish only on_rating message
#   ./publish-all.sh on_support   # Publish only on_support message
#   ./publish-all.sh catalog_publish    # Publish only catalog_publish message
#   ./publish-all.sh on_catalog_publish # Publish only on_catalog_publish message
#
# Supported actions: on_discover, on_select, on_init, on_confirm, on_status,
#                    on_track, on_cancel, on_update, on_rating, on_support,
#                    catalog_publish, on_catalog_publish

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/publish-common.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ACTION=${1:-all}

# Function to get topic from action
# These messages act like BPP Backend producer publishing callbacks
# BPP Backend publishes to bpp.on_* topics (callbacks from BPP Backend)
# The BPP plugin's bppTxnCaller consumes from bpp.on_* topics
get_topic() {
  local action=$1
  case "$action" in
    on_discover)
      echo "bpp.on_discover"
      ;;
    on_select|on_init|on_confirm|on_status|on_track|on_cancel|on_update|on_rating|on_support|on_catalog_publish)
      echo "bpp.${action}"
      ;;
    catalog_publish)
      echo "bpp.catalog_publish"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Function to get action from JSON file
get_action_from_file() {
  local json_file=$1
  if [ ! -f "$json_file" ]; then
    echo ""
    return
  fi
  
  # Try to extract action from JSON context.action field
  if command -v jq &> /dev/null; then
    jq -r '.context.action // empty' "$json_file" 2>/dev/null || echo ""
  else
    # Fallback: extract from filename
    basename "$json_file" .json
  fi
}

# Function to get description from filename
get_description_from_filename() {
  local filename=$(basename "$1" .json)
  # Convert kebab-case to Title Case
  echo "$filename" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1'
}

echo "=========================================="
echo "BPP Kafka Message Publisher"
echo "=========================================="
echo "Kafka: ${KAFKA_BOOTSTRAP}"
echo "Example Directory: ${EXAMPLE_DIR}"
echo "Action Filter: ${ACTION}"
echo ""

# Check if example directory exists
if [ ! -d "$EXAMPLE_DIR" ]; then
  echo -e "${RED}Error: Example directory not found: ${EXAMPLE_DIR}${NC}"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${RED}Error: jq is required but not installed.${NC}"
  echo "Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

# Find all JSON files
JSON_FILES=($(find "$EXAMPLE_DIR" -name "*.json" -type f | sort))

if [ ${#JSON_FILES[@]} -eq 0 ]; then
  echo -e "${RED}No JSON files found in ${EXAMPLE_DIR}${NC}"
  exit 1
fi

echo -e "${BLUE}Found ${#JSON_FILES[@]} JSON file(s)${NC}"
echo ""

SUCCESS=0
FAILED=0
SKIPPED=0

# Process each JSON file
for json_file in "${JSON_FILES[@]}"; do
  # Get action from file
  file_action=$(get_action_from_file "$json_file")
  
  # Skip if we can't determine action
  if [ -z "$file_action" ]; then
    echo -e "${YELLOW}⚠ Skipping $(basename "$json_file"): Could not determine action${NC}"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  
  # Filter by action if specified
  if [ "$ACTION" != "all" ] && [ "$ACTION" != "$file_action" ]; then
    continue
  fi
  
  # Get topic
  topic=$(get_topic "$file_action")
  
  if [ -z "$topic" ]; then
    echo -e "${YELLOW}⚠ Skipping $(basename "$json_file"): Unknown action '${file_action}'${NC}"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  
  # Get description
  description=$(get_description_from_filename "$json_file")
  
  # Publish message
  if publish_message "$topic" "$json_file" "$description"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  
  # Small delay between messages
  sleep 0.5
done

# Summary
echo -e "\n=========================================="
echo "Summary"
echo "=========================================="
echo -e "${GREEN}Success: ${SUCCESS}${NC}"
if [ $FAILED -gt 0 ]; then
  echo -e "${RED}Failed: ${FAILED}${NC}"
fi
if [ $SKIPPED -gt 0 ]; then
  echo -e "${YELLOW}Skipped: ${SKIPPED}${NC}"
fi
echo ""

if [ $FAILED -eq 0 ] && [ $SUCCESS -gt 0 ]; then
  exit 0
else
  exit 1
fi

