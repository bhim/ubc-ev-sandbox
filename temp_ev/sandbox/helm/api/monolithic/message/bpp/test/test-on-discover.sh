#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/../bap/test/api-common.sh"
JSON_FILE="${EXAMPLE_DIR}/on_discover.json"
ENDPOINT="/bpp/caller/on_discover"
DESCRIPTION="On Discover"
if [ ! -f "$JSON_FILE" ]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi
send_api_request "$ENDPOINT" "$JSON_FILE" "$DESCRIPTION" "bpp"

