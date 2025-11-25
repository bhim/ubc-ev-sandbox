# BPP API Test Messages - Helm Sandbox

This directory contains pre-formatted JSON messages and bash scripts for testing BPP (Buyer Platform Provider) APIs via REST/HTTP endpoints in the Helm-deployed sandbox environment.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Test All Messages** - Automatically tests all JSON files from `example/` directory:
```bash
cd sandbox/helm/api/monolithic/message/bpp/test && ./test-all.sh
```

**📝 Test Single Message:**
```bash
# Test on_discover response
cd sandbox/helm/api/monolithic/message/bpp/test && ./test-on-discover.sh

# Test on_select response
cd sandbox/helm/api/monolithic/message/bpp/test && ./test-on-select.sh
```

## Prerequisites

1. **Services Deployed**: BAP and BPP adapters must be deployed via Helm
2. **Port Forwarding** (if using ClusterIP):
   ```bash
   kubectl port-forward svc/ev-charging-bap-onix-api-monolithic-bap-service 8001:8001 &
   kubectl port-forward svc/ev-charging-bpp-onix-api-monolithic-bpp-service 8002:8002 &
   ```
3. **Required Tools**:
   - `curl` - For HTTP requests
   - `jq` - For JSON processing
     - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)
   - `uuidgen` or `python3` - For generating UUIDs (scripts have fallback)

## Configuration

Scripts use environment variables for configuration (same as BAP):

```bash
# Service URLs (defaults to localhost with port forwarding)
export BAP_URL="http://localhost:8001"
export BPP_URL="http://localhost:8002"

# Kubernetes service names
export BAP_SERVICE="ev-charging-bap-onix-api-monolithic-bap-service"
export BPP_SERVICE="ev-charging-bpp-onix-api-monolithic-bpp-service"
export MOCK_BAP_SERVICE="ev-charging-mock-bap"
export MOCK_BPP_SERVICE="ev-charging-mock-bpp"
```

## Directory Structure

```
message/bpp/
├── README.md                     # This file
├── example/                      # JSON message files (on_discover, on_select, …)
└── test/                         # Bash scripts for API testing
    ├── api-common.sh             # Links to BAP common functions
    ├── test-all.sh               # Tests every payload
    └── test-*.sh                 # Individual message scripts
```

## Available Test Messages

| Action | File | Endpoint |
|--------|------|----------|
| on_discover | `on_discover.json` | `/bpp/caller/on_discover` |
| on_select | `on_select.json` | `/bpp/caller/on_select` |
| on_init | `on_init.json` | `/bpp/caller/on_init` |
| on_confirm | `on_confirm.json` | `/bpp/caller/on_confirm` |
| on_status | `on_status.json` | `/bpp/caller/on_status` |
| on_track | `on_track.json` | `/bpp/caller/on_track` |
| on_cancel | `on_cancel.json` | `/bpp/caller/on_cancel` |
| on_update | `on_update.json` | `/bpp/caller/on_update` |
| on_rating | `on_rating.json` | `/bpp/caller/on_rating` |
| on_support | `on_support.json` | `/bpp/caller/on_support` |

## Message Flow

These scripts act like BPP Backend, sending HTTP responses to the BPP adapter's caller endpoints.

### Phase 1: On_Discover Flow
1. Script sends `on_discover.json` message to `/bpp/caller/on_discover`
2. ONIX BPP plugin processes and routes to Mock CDS for aggregation
3. CDS aggregates and forwards to BAP

### Phase 2+: Transaction Response Flow
1. Script sends response message (on_select, on_init, etc.) to `/bpp/caller/{action}`
2. ONIX BPP plugin processes and routes directly to BAP via HTTP
3. BAP adapter receives callback at `/bap/receiver/{action}` endpoint

## Using curl Directly

You can also send messages directly using curl:

```bash
# Send an on_discover response
curl -X POST http://localhost:8002/bpp/caller/on_discover \
  -H "Content-Type: application/json" \
  -d @example/on_discover.json

# Send an on_select response
curl -X POST http://localhost:8002/bpp/caller/on_select \
  -H "Content-Type: application/json" \
  -d @example/on_select.json
```

**Note**: Update service URIs in JSON files to match your Kubernetes service names before sending.

## Testing from Within Kubernetes Cluster

If you want to test from within the cluster:

```bash
# Create a test pod
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- sh

# Inside the pod, test BPP endpoint
curl -X POST http://ev-charging-bpp-onix-api-monolithic-bpp-service:8002/bpp/caller/on_discover \
  -H "Content-Type: application/json" \
  -d @example/on_discover.json
```

## Troubleshooting

See `../bap/README.md` for troubleshooting tips. Most issues are similar:
- Connection refused → Check port forwarding
- 404/500 errors → Verify endpoints and JSON structure
- Service name resolution → Update service names in configuration

## Additional Resources

- **BAP Test Messages**: See `../bap/README.md` for BAP endpoint testing
- **Main README**: See `../../README.md` for deployment instructions
- **Postman Collections**: Use Postman collections in `api-collection/postman-collection/` for GUI-based testing

