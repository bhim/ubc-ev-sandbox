#!/bin/bash

# Producer: Publishes on_rating message to RabbitMQ
# This acts like BPP Backend producer, publishing callbacks to bpp.on_rating routing key
# Messages will be consumed by BPP plugin's bppTxnCaller module from bpp_caller_queue
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/publish-common.sh"

publish_message "bpp.on_rating" "${EXAMPLE_DIR}/on_rating.json" "On Rating"
