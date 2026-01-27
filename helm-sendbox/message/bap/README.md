# BAP API Test Messages - Helm Sandbox

This directory contains pre-formatted JSON messages and bash scripts for testing BAP (Buyer App Provider) APIs via REST/HTTP endpoints in the Helm-deployed sandbox environment.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Test All Messages** - Automatically tests all JSON files from `example/` directory:
```bash
cd helm-sendbox/message/bap/test && ./test-all.sh
```

**🎯 Test Specific Action Type:**
```bash
# Test all discover variants
cd helm-sendbox/message/bap/test && ./test-all.sh discover

# Test select action
cd helm-sendbox/message/bap/test && ./test-select.sh
```

**📝 Test Single Message:**
```bash
# Discover messages
cd helm-sendbox/message/bap/test && ./test-discover-by-station.sh
cd helm-sendbox/message/bap/test && ./test-discover-by-evse.sh

# Transaction messages
cd helm-sendbox/message/bap/test && ./test-select.sh
cd helm-sendbox/message/bap/test && ./test-init.sh
cd helm-sendbox/message/bap/test && ./test-confirm.sh
```

## Prerequisites

1. **Services Deployed**: BAP and BPP adapters must be deployed via Helm
2. **Port Forwarding** (if using ClusterIP):
   ```bash
   kubectl port-forward svc/onix-bap-service 8001:8001 -n ev-charging-sandbox &
   kubectl port-forward svc/onix-bpp-service 8002:8002 -n ev-charging-sandbox &
   ```
3. **Required Tools**:
   - `curl` - For HTTP requests
   - `jq` - For JSON processing
     - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)
   - `uuidgen` or `python3` - For generating UUIDs (scripts have fallback)

## Configuration

Scripts use environment variables for configuration:

```bash
# Service URLs (defaults to localhost with port forwarding)
export BAP_URL="http://localhost:8001"
export BPP_URL="http://localhost:8002"

# Kubernetes service names (for message adaptation)
export BAP_SERVICE="onix-bap-service"
export BPP_SERVICE="onix-bpp-service"
export MOCK_BAP_SERVICE="mock-bap"
export MOCK_BPP_SERVICE="mock-bpp"
export MOCK_CDS_SERVICE="mock-cds"
export MOCK_REGISTRY_SERVICE="mock-registry"

# Namespace (if using port forwarding)
export NAMESPACE="ev-charging-sandbox"
```

## Directory Structure

```
message/bap/
├── README.md                     # This file
├── example/                      # JSON message files (discover, select, init, …)
└── test/                         # Bash scripts for API testing
    ├── api-common.sh             # Common functions (UUID/timestamp updates + curl)
    ├── test-all.sh               # Tests every payload (optionally filtered by action)
    └── test-*.sh                 # Individual message scripts (one per JSON file)
```

## Message Flow

These scripts act like BAP Backend, sending HTTP requests to the BAP adapter's caller endpoints.

### Phase 1: Discover Flow
1. Script sends `discover-*.json` message to `/bap/caller/discover`
2. ONIX BAP plugin processes and routes to Mock CDS for aggregation
3. Response sent to BAP backend at `bap_uri` specified in context

### Phase 2+: Transaction Flow
1. Script sends transaction message (select, init, confirm, etc.) to `/bap/caller/{action}`
2. ONIX BAP plugin processes and routes directly to BPP via HTTP
3. BPP adapter sends callback to BAP plugin's `/bap/receiver/{action}` endpoint
4. BAP plugin forwards response to BAP backend at `bap_uri`

## Using curl Directly

You can also send messages directly using curl:

```bash
# Send a discover request
curl -X POST http://localhost:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d @example/discover-by-station.json

# Send a select request
curl -X POST http://localhost:8001/bap/caller/select \
  -H "Content-Type: application/json" \
  -d @example/select.json
```

**Note**: Update `bap_uri` and `bpp_uri` in JSON files to match your Kubernetes service names before sending.

## Testing from Within Kubernetes Cluster

If you want to test from within the cluster:

```bash
# Create a test pod
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- sh

# Inside the pod, test BAP endpoint
curl -X POST http://onix-bap-service:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "version": "2.0.0",
      "action": "discover",
      "domain": "beckn.one:deg:ev-charging",
      "bap_id": "ev-charging.sandbox1.com",
      "bap_uri": "http://onix-bap-service:8001/bap/receiver",
      "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
      "message_id": "440e8400-e29b-41d4-a716-446655440012",
      "timestamp": "2025-01-27T10:00:00Z",
      "ttl": "PT30S"
    },
    "message": {
      "filters": {
        "type": "jsonpath",
        "expression": "$[?(@.beckn:id==\"ITEM-BTM-DC60\")]"
      }
    }
  }'
```

## Troubleshooting

### Scripts Fail with "jq: command not found"
Install jq:
```bash
# macOS
brew install jq

# Linux
apt-get install jq
```

### Scripts Fail with "Connection refused"
- Verify services are running: `kubectl get pods -n ev-charging-sandbox`
- Check port forwarding: `kubectl port-forward svc/onix-bap-service 8001:8001 -n ev-charging-sandbox`
- Verify service URLs: `kubectl get svc -n ev-charging-sandbox`

### Messages Return 404 or 500 Errors
- Verify endpoint paths are correct
- Check adapter logs: `kubectl logs -n ev-charging-sandbox -l component=bap`
- Verify JSON structure: `jq . example/discover-by-station.json`

### Service Names Not Resolved
- Update service names in `api-common.sh` or set environment variables
- Verify service names: `kubectl get svc -n ev-charging-sandbox`

## Additional Resources

- **BPP Test Messages**: See `../bpp/README.md` for BPP endpoint testing
- **Main README**: See `../../README.md` for deployment instructions
- **Postman Collections**: Use Postman collections in `api-collection/postman-collection/` for GUI-based testing

