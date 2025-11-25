#!/bin/bash

# Producer: Publishes select message to RabbitMQ
# This acts like BAP Backend producer, publishing requests to bap.select routing key
# Messages will be consumed by BAP plugin's bapTxnCaller module from bap_caller_queue
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/publish-common.sh"

publish_message "bap.select" "${EXAMPLE_DIR}/select.json" "Select"

