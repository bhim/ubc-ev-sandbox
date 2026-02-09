#!/bin/bash

# Test all BPP API endpoints

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
echo -e "${YELLOW}Testing All BPP API Endpoints${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test all JSON files
for file in "${EXAMPLE_DIR}"/*.json; do
  if [ ! -f "$file" ]; then
    continue
  fi
  
  filename=$(basename "$file" .json)
  
  # Apply filter if provided
  if [ ! -z "$FILTER" ] && [[ ! "$filename" =~ $FILTER ]]; then
    continue
  fi
  
  # BPP files use the filename directly as endpoint (with /bpp/caller/ prefix)
  endpoint="/bpp/caller/${filename}"
  
  TOTAL=$((TOTAL + 1))
  
  description=$(echo "$filename" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
  
  if send_api_request "$endpoint" "$file" "$description" "bpp"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  
  # Small delay between requests
  sleep 0.5
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

