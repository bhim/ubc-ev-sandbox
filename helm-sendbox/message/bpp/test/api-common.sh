#!/bin/bash

# Common functions for BPP API testing with curl
# This is a symlink/copy of bap/api-common.sh but can be customized for BPP

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source the BAP api-common.sh (go up from bpp/test to message, then into bap/test)
source "${SCRIPT_DIR}/../../bap/test/api-common.sh"

