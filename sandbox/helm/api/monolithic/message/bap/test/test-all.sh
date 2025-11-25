#!/bin/bash

# Test all BAP API endpoints

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/api-common.sh"

# Filter argument (optional)
FILTER="${1:-}"

# Counters
TOTAL=0
SUCCESS=0
FAILED=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Testing All BAP API Endpoints${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to test a file
test_file() {
  local file=$1
  local filename=$(basename "$file" .json)
  local action
  local endpoint
  
  # Map filename to action endpoint
  case "$filename" in
    discover-*) 
      action="discover"
      endpoint="/bap/caller/discover"
      ;;
    select) 
      action="select"
      endpoint="/bap/caller/select"
      ;;
    init) 
      action="init"
      endpoint="/bap/caller/init"
      ;;
    confirm) 
      action="confirm"
      endpoint="/bap/caller/confirm"
      ;;
    update) 
      action="update"
      endpoint="/bap/caller/update"
      ;;
    track) 
      action="track"
      endpoint="/bap/caller/track"
      ;;
    cancel) 
      action="cancel"
      endpoint="/bap/caller/cancel"
      ;;
    rating) 
      action="rating"
      endpoint="/bap/caller/rating"
      ;;
    support) 
      action="support"
      endpoint="/bap/caller/support"
      ;;
    *) 
      echo -e "${YELLOW}Skipping unknown file: $filename${NC}"
      return 0
      ;;
  esac
  
  # Apply filter if provided
  if [ ! -z "$FILTER" ] && [ "$action" != "$FILTER" ]; then
    return 0
  fi
  
  TOTAL=$((TOTAL + 1))
  
  if send_api_request "$endpoint" "$file" "$action (from $filename.json)" "bap"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  
  # Small delay between requests
  sleep 0.5
}

# Test all JSON files
for file in "${EXAMPLE_DIR}"/*.json; do
  if [ -f "$file" ]; then
    test_file "$file"
  fi
done

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Total: $TOTAL"
echo -e "  ${GREEN}Success: $SUCCESS${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi

