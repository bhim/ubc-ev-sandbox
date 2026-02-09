#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/api-common.sh"
JSON_FILE="${EXAMPLE_DIR}/select.json"
ENDPOINT="/bap/caller/select"
DESCRIPTION="Select"
if [ ! -f "$JSON_FILE" ]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi
send_api_request "$ENDPOINT" "$JSON_FILE" "$DESCRIPTION" "bap"

