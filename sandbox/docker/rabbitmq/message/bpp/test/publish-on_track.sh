#!/bin/bash

# Producer: Publishes on_track message to RabbitMQ
# This acts like BPP Backend producer, publishing callbacks to bpp.on_track routing key
# Messages will be consumed by BPP plugin's bppTxnCaller module from bpp_caller_queue
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="${SCRIPT_DIR}/../example"
source "${SCRIPT_DIR}/publish-common.sh"

publish_message "bpp.on_track" "${EXAMPLE_DIR}/on_track.json" "On Track"
