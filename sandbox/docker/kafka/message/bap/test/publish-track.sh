#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/publish-common.sh"
JSON_FILE="${EXAMPLE_DIR}/track.json"
TOPIC="bap.track"
DESCRIPTION=""
if [ ! -f "$JSON_FILE" ]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi
publish_message "$TOPIC" "$JSON_FILE" "$DESCRIPTION"
