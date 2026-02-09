#!/bin/bash

# Producer: Publishes discover-within-boundary message to RabbitMQ
# This acts like BAP Backend producer, publishing requests to bap.discover routing key
# Messages will be consumed by BAP plugin's bapTxnCaller module from bap_caller_queue
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/publish-common.sh"

publish_message "bap.discover" "${EXAMPLE_DIR}/discover-within-boundary.json" "Discover within boundary"

