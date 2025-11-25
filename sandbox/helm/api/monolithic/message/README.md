# API Test Messages - Helm Sandbox

This directory contains pre-formatted JSON test messages and bash scripts for testing the ONIX adapters deployed via Helm in the Kubernetes sandbox environment.

## Overview

These test messages are adapted from the Kafka message directory (`sandbox/docker/kafka/message/`) but configured for REST/HTTP API testing with Kubernetes service names.

## Directory Structure

```
message/
├── README.md                     # This file
├── bap/                          # BAP (Buyer App Provider) test messages
│   ├── README.md                # BAP-specific documentation
│   ├── example/                 # JSON message files
│   │   ├── discover-*.json     # Discover request variants
│   │   ├── select.json         # Select request
│   │   ├── init.json           # Init request
│   │   ├── confirm.json        # Confirm request
│   │   └── ...                 # Other action requests
│   └── test/                    # Test scripts
│       ├── api-common.sh       # Common functions
│       ├── test-all.sh         # Test all messages
│       └── test-*.sh           # Individual test scripts
└── bpp/                          # BPP (Buyer Platform Provider) test messages
    ├── README.md                # BPP-specific documentation
    ├── example/                 # JSON message files
    │   ├── on_discover.json    # On discover response
    │   ├── on_select.json      # On select response
    │   └── ...                 # Other response messages
    └── test/                    # Test scripts
        ├── api-common.sh       # Links to BAP common functions
        ├── test-all.sh         # Test all messages
        └── test-*.sh           # Individual test scripts
```

## Quick Start

### Prerequisites

1. **Deploy Services**: Deploy BAP and BPP adapters using Helm
   ```bash
   cd sandbox/helm/api/monolithic
   helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
     -f ../../../../helm/api/monolithic/values-bap.yaml \
     -f values-sandbox.yaml \
     --set component=bap \
     --namespace ev-charging-sandbox \
     --create-namespace
   ```

2. **Port Forward Services** (if using ClusterIP):
   ```bash
   kubectl port-forward svc/ev-charging-bap-onix-api-monolithic-bap-service 8001:8001 &
   kubectl port-forward svc/ev-charging-bpp-onix-api-monolithic-bpp-service 8002:8002 &
   ```

3. **Install Required Tools**:
   ```bash
   # macOS
   brew install jq curl
   
   # Linux
   apt-get install jq curl
   ```

### Test BAP Endpoints

```bash
# Test all BAP endpoints
cd sandbox/helm/api/monolithic/message/bap/test
./test-all.sh

# Test specific action
./test-all.sh discover
./test-select.sh
```

### Test BPP Endpoints

```bash
# Test all BPP endpoints
cd sandbox/helm/api/monolithic/message/bpp/test
./test-all.sh

# Test specific endpoint
./test-on-discover.sh
```

## Configuration

Test scripts use environment variables that can be customized:

```bash
# Service URLs (defaults to localhost with port forwarding)
export BAP_URL="http://localhost:8001"
export BPP_URL="http://localhost:8002"

# Kubernetes service names
export BAP_SERVICE="ev-charging-bap-onix-api-monolithic-bap-service"
export BPP_SERVICE="ev-charging-bpp-onix-api-monolithic-bpp-service"
export MOCK_BAP_SERVICE="ev-charging-mock-bap"
export MOCK_BPP_SERVICE="ev-charging-mock-bpp"
export MOCK_CDS_SERVICE="ev-charging-mock-cds"

# Namespace
export NAMESPACE="ev-charging-sandbox"
```

## Message Adaptation

The test scripts automatically adapt messages for Kubernetes:

1. **Service Names**: Updates `bap_uri` and `bpp_uri` to use Kubernetes service names
2. **Dynamic IDs**: Generates new `transaction_id` and `message_id` for each request
3. **Timestamps**: Updates `timestamp` to current UTC time

## Using Messages Directly with curl

You can also use the JSON files directly with curl:

```bash
# Test BAP discover
curl -X POST http://localhost:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d @bap/example/discover-by-station.json

# Test BPP on_discover
curl -X POST http://localhost:8002/bpp/caller/on_discover \
  -H "Content-Type: application/json" \
  -d @bpp/example/on_discover.json
```

**Note**: Remember to update service URIs in JSON files if not using the test scripts.

## Testing from Within Kubernetes

To test from within the cluster:

```bash
# Create a test pod
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- sh

# Copy message files into pod (or use inline JSON)
# Then test endpoints using Kubernetes service names
curl -X POST http://ev-charging-bap-onix-api-monolithic-bap-service:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d @/path/to/discover-by-station.json
```

## Available Test Messages

### BAP Messages (Outgoing Requests)

- **Discover**: 8 variants (by station, EVSE, CPO, route, boundary, timerange, connector spec, vehicle spec)
- **Select**: Order selection request
- **Init**: Order initialization request
- **Confirm**: Order confirmation request
- **Update**: Order update request
- **Track**: Order tracking request
- **Cancel**: Order cancellation request
- **Rating**: Rating submission request
- **Support**: Support request

### BPP Messages (Outgoing Responses)

- **on_discover**: Discovery response
- **on_select**: Selection response
- **on_init**: Initialization response
- **on_confirm**: Confirmation response
- **on_status**: Status update response
- **on_track**: Tracking response
- **on_cancel**: Cancellation response
- **on_update**: Update response
- **on_rating**: Rating response
- **on_support**: Support response

## Troubleshooting

### Connection Issues

- **Connection refused**: Ensure port forwarding is active or services are exposed via LoadBalancer/NodePort
- **Service not found**: Verify service names match your deployment
- **404 errors**: Check endpoint paths match your adapter configuration

### Script Issues

- **jq not found**: Install jq (`brew install jq` or `apt-get install jq`)
- **Permission denied**: Make scripts executable (`chmod +x test/*.sh`)
- **JSON errors**: Validate JSON files (`jq . example/discover-by-station.json`)

### Service Issues

- **Pods not running**: Check pod status (`kubectl get pods -n ev-charging-sandbox`)
- **Service not accessible**: Verify service endpoints (`kubectl get endpoints -n ev-charging-sandbox`)
- **Adapter errors**: Check adapter logs (`kubectl logs -n ev-charging-sandbox -l component=bap`)

## Additional Resources

- **BAP Documentation**: See `bap/README.md` for detailed BAP testing guide
- **BPP Documentation**: See `bpp/README.md` for detailed BPP testing guide
- **Deployment Guide**: See `../../README.md` for Helm deployment instructions
- **Postman Collections**: Use Postman collections in `api-collection/postman-collection/` for GUI-based testing
- **Swagger Documentation**: See `api-collection/swagger/` for API specifications

## Differences from Kafka Messages

These messages are adapted from the Kafka message directory with the following changes:

1. **Transport**: Uses HTTP/REST instead of Kafka topics
2. **Service Names**: Updated to use Kubernetes service names instead of Docker container names
3. **Endpoints**: Messages are sent to HTTP endpoints (`/bap/caller/{action}`, `/bpp/caller/{action}`)
4. **Testing**: Uses curl-based scripts instead of Kafka producer scripts

The JSON message structure remains the same, only the transport mechanism and service references differ.

