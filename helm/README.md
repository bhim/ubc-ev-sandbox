# Helm Chart - Monolithic Architecture - API Integration

This guide demonstrates how to deploy the **onix-adapter** using **Helm charts** in a **monolithic architecture** with **REST API** communication on **Kubernetes**.

## Key Features

- **Schema Validation v2**: Uses `schemav2validator` with URL-based schema validation from Beckn protocol specifications
- **OpenTelemetry Metrics**: Built-in OTEL metrics support (port 9003 for BAP, 9004 for BPP)
- **Secret Management**: Production-ready secret management with Kubernetes Secrets and fallback to hardcoded values
- **Simplified Service Names**: Clean service naming convention (mock-registry, mock-cds, mock-bap, mock-bpp)
- **Routing Configuration**: Flexible routing with Phase 1 (CDS aggregation) and Phase 2+ (direct BPP routing) support
- **BAP/BPP Support**: Separate configurations for BAP and BPP adapters with component-specific settings

## Architecture Overview

Deploy onix-adapter as a monolithic application on Kubernetes using Helm charts. In this architecture, the onix-adapter runs as a single pod/service that handles both incoming and outgoing API requests. All communication happens via HTTP/REST API endpoints.

### Components

- **Redis**: Used for caching and state management (deployed as a separate service)
- **Onix-Adapter**: Single pod handling all BAP/BPP operations
- **API Communication**: Direct HTTP/REST API calls between services
- **Kubernetes Services**: Service objects for service discovery and load balancing

## Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to onix-adapter Docker images:
  - `manendrapalsingh/onix-bap-plugin:latest`
  - `manendrapalsingh/onix-bpp-plugin:latest`
- Persistent volume support (for Redis if using persistent storage)

## Directory Structure

```
helm/
├── Chart.yaml                    # Helm chart metadata
├── values.yaml                   # Default configuration values
├── values-bap.yaml              # BAP-specific values
├── values-bpp.yaml              # BPP-specific values
├── templates/
│   ├── _helpers.tpl             # Template helpers
│   ├── deployment.yaml          # Kubernetes deployment
│   ├── service.yaml             # Kubernetes service
│   ├── configmap.yaml           # Configuration files
│   └── redis.yaml                # Redis deployment (optional)
└── README.md                    # This file
```

### Key Features

- **Schema Validation**: Uses `schemav2validator` with URL-based schema validation
- **OTEL Metrics**: OpenTelemetry metrics enabled (port 9003 for BAP, 9004 for BPP)
- **Secret Management**: Support for Kubernetes Secrets with fallback to hardcoded values
- **Routing Configuration**: Routing files mounted at `/app/config/` for easy access
- **Service Discovery**: Simplified service names (mock-registry, mock-cds, etc.)

## Quick Start

### Deploy All Services (BAP and BPP)

Deploy both BAP and BPP adapters together:

```bash
# Navigate to the helm chart directory
cd helm

# Deploy BAP adapter
helm upgrade --install onix-bap . -f values-bap.yaml

# Deploy BPP adapter
helm upgrade --install onix-bpp . -f values-bpp.yaml

# Check deployment status
kubectl get pods -l app=onix-bap
kubectl get pods -l app=onix-bpp
kubectl get svc -l 'app in (onix-bap,onix-bpp)'
```

**Or deploy both in one command:**

```bash
# Deploy both BAP and BPP adapters
helm upgrade --install onix-bap ./helm -f ./helm/values-bap.yaml && \
helm upgrade --install onix-bpp ./helm -f ./helm/values-bpp.yaml

# Check all services
kubectl get pods -l 'app in (onix-bap,onix-bpp)'
kubectl get svc -l 'app in (onix-bap,onix-bpp)'
```

### Deploy Individual Services

#### Install BAP Adapter

```bash
# Install with default values
helm install onix-bap ./helm -f ./helm/values-bap.yaml

# Or install with custom values
helm install onix-bap ./helm -f ./helm/values-bap.yaml --set image.tag=v1.0.0

# Or use upgrade --install for idempotent deployment (recommended)
helm upgrade --install onix-bap ./helm -f ./helm/values-bap.yaml
```

#### Install BPP Adapter

```bash
# Install with default values
helm install onix-bpp ./helm -f ./helm/values-bpp.yaml

# Or install with custom values
helm install onix-bpp ./helm -f ./helm/values-bpp.yaml --set image.tag=v1.0.0

# Or use upgrade --install for idempotent deployment (recommended)
helm upgrade --install onix-bpp ./helm -f ./helm/values-bpp.yaml
```

### Check Status

```bash
# Check Helm release status
helm status onix-bap
helm status onix-bpp

# Check pod status
kubectl get pods -l app=onix-bap
kubectl get pods -l app=onix-bpp

# Check services
kubectl get svc -l app=onix-bap
kubectl get svc -l app=onix-bpp

# Check all services at once
kubectl get pods,svc -l 'app in (onix-bap,onix-bpp)'
```

## Configuration

### Values File Structure

The Helm chart uses `values.yaml` files to configure the deployment. Key configuration areas include:

#### Application Configuration

```yaml
appName: onix-ev-charging
image:
  repository: manendrapalsingh/onix-bap-plugin
  tag: latest
  pullPolicy: IfNotPresent

replicaCount: 1

service:
  type: ClusterIP
  port: 8001
  targetPort: 8001
```

#### Redis Configuration

```yaml
redis:
  enabled: true
  image:
    repository: redis
    tag: 7-alpine
  service:
    port: 6379
  persistence:
    enabled: false
```

#### Adapter Configuration

```yaml
config:
  # Keys for fallback when secrets are not enabled
  keys:
    signingPrivateKey: ""
    signingPublicKey: ""
    encrPrivateKey: ""
    encrPublicKey: ""
  
  adapter: |
    # Adapter configuration (mounted as ConfigMap)
    appName: onix-ev-charging  # Use "bpp-ev-charging" for BPP
    http:
      port: 8001  # Use 8002 for BPP
    
    plugins:
      otelsetup:
        id: otelsetup
        config:
          serviceName: "beckn-onix"
          serviceVersion: "1.0.0"
          enableMetrics: "true"
          environment: "development"
          metricsPort: "9003"  # Use "9004" for BPP
    
    modules:
      - name: bapTxnReceiver  # Use bppTxnReceiver for BPP
        handler:
          plugins:
            schemaValidator:
              id: schemav2validator
              config:
                type: url
                location: https://raw.githubusercontent.com/beckn/protocol-specifications-v2/refs/heads/core-v2.0.0-rc/api/beckn.yaml
                cacheTTL: "3600"
            router:
              config:
                routingConfig: /app/config/bap_receiver_routing.yaml  # Use bpp_receiver_routing.yaml for BPP
  
  routing:
    # Routing configuration files
    caller: |
      # Routing rules YAML
    receiver: |
      # Routing rules YAML
```

#### Secret Management Configuration

```yaml
secrets:
  enabled: false  # Set to true in production
  secretName: ""  # Kubernetes secret name (e.g., "onix-bap-secrets" or "onix-bpp-secrets")
  # If secretName is empty or secret doesn't exist, use hardcoded values from config.keys
```

### Environment Variables

```yaml
env:
  - name: CONFIG_FILE
    value: /app/config/adapter.yaml
  - name: LOG_LEVEL
    value: info
```

**Note**: When secrets are enabled, the following environment variables are automatically set from Kubernetes Secrets:
- `SIGNING_PRIVATE_KEY`
- `SIGNING_PUBLIC_KEY`
- `ENCR_PRIVATE_KEY`
- `ENCR_PUBLIC_KEY`

These environment variables override the values in adapter.yaml at runtime. If secrets are disabled, the hardcoded values from `config.keys` are used.

### Resource Limits

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Deployment Options

### Option 1: Deploy with Embedded Redis

Redis is deployed as part of the Helm chart:

```bash
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set redis.enabled=true
```

### Option 2: Deploy with External Redis

Use an existing Redis instance:

```bash
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set redis.enabled=false \
  --set config.redis.host=external-redis-service \
  --set config.redis.port=6379
```

### Option 3: Deploy with Custom Configuration

Override specific values:

```bash
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set image.tag=v1.0.0 \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```

### Option 4: Deploy with Secret Management (Production)

Use Kubernetes Secrets for signing keys:

```bash
# First, create the Kubernetes Secret
kubectl create secret generic onix-bap-secrets \
  --from-literal=signingPrivateKey='your-private-key' \
  --from-literal=signingPublicKey='your-public-key' \
  --from-literal=encrPrivateKey='your-encr-private-key' \
  --from-literal=encrPublicKey='your-encr-public-key'

# Deploy with secrets enabled
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bap-secrets
```

For BPP:

```bash
kubectl create secret generic onix-bpp-secrets \
  --from-literal=signingPrivateKey='your-private-key' \
  --from-literal=signingPublicKey='your-public-key' \
  --from-literal=encrPrivateKey='your-encr-private-key' \
  --from-literal=encrPublicKey='your-encr-public-key'

helm install onix-bpp ./helm \
  -f ./helm/values-bpp.yaml \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bpp-secrets
```

## Service Endpoints

Once deployed, the services are accessible via Kubernetes services:

### All Services Overview

| Service | Service Name | Port | Caller Endpoint | Receiver Endpoint |
|---------|--------------|------|----------------|-------------------|
| **BAP** | `onix-bap-service` | 8001 | `http://onix-bap-service:8001/bap/caller/{action}` | `http://onix-bap-service:8001/bap/receiver/{action}` |
| **BPP** | `onix-bpp-service` | 8002 | `http://onix-bpp-service:8002/bpp/caller/{action}` | `http://onix-bpp-service:8002/bpp/receiver/{action}` |

### BAP Service

- **Service Name**: `onix-bap-service`
- **Port**: 8001
- **Caller Endpoint**: `http://onix-bap-service:8001/bap/caller/{action}`
- **Receiver Endpoint**: `http://onix-bap-service:8001/bap/receiver/{action}`

### BPP Service

- **Service Name**: `onix-bpp-service`
- **Port**: 8002
- **Caller Endpoint**: `http://onix-bpp-service:8002/bpp/caller/{action}`
- **Receiver Endpoint**: `http://onix-bpp-service:8002/bpp/receiver/{action}`

### Access from Outside Cluster

If using `LoadBalancer` or `NodePort` service type:

```bash
# Get external IPs for all services
kubectl get svc -l 'app in (onix-bap,onix-bpp)'

# Get external IP for BAP (LoadBalancer)
kubectl get svc onix-bap-service

# Get external IP for BPP (LoadBalancer)
kubectl get svc onix-bpp-service

# Get NodePort for BAP
kubectl get svc onix-bap-service -o jsonpath='{.spec.ports[0].nodePort}'

# Get NodePort for BPP
kubectl get svc onix-bpp-service -o jsonpath='{.spec.ports[0].nodePort}'
```

### Port Forwarding (Alternative Access Method)

If services are ClusterIP type, use port forwarding to access them locally:

```bash
# Port forward BAP service (run in separate terminal)
kubectl port-forward svc/onix-bap-service 8001:8001

# Port forward BPP service (run in separate terminal)
kubectl port-forward svc/onix-bpp-service 8002:8002

# Access services locally after port forwarding
# BAP: http://localhost:8001/bap/caller/{action}
# BPP: http://localhost:8002/bpp/caller/{action}
```

## Upgrading

### Upgrade All Services

```bash
# Upgrade both BAP and BPP adapters
helm upgrade onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set image.tag=v1.1.0 && \
helm upgrade onix-bpp ./helm \
  -f ./helm/values-bpp.yaml \
  --set image.tag=v1.1.0

# Or use upgrade --install for idempotent upgrades (recommended)
helm upgrade --install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set image.tag=v1.1.0 && \
helm upgrade --install onix-bpp ./helm \
  -f ./helm/values-bpp.yaml \
  --set image.tag=v1.1.0

# Check upgrade status
helm status onix-bap
helm status onix-bpp
kubectl get pods -l 'app in (onix-bap,onix-bpp)'
```

### Upgrade Individual Release

```bash
# Upgrade BAP with new values
helm upgrade onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set image.tag=v1.1.0

# Upgrade BPP with new values
helm upgrade onix-bpp ./helm \
  -f ./helm/values-bpp.yaml \
  --set image.tag=v1.1.0

# Check upgrade status
helm status onix-bap
helm status onix-bpp
```

### Rollback

```bash
# List release history for all services
helm history onix-bap
helm history onix-bpp

# Rollback BAP to previous version
helm rollback onix-bap 1

# Rollback BPP to previous version
helm rollback onix-bpp 1

# Rollback both services
helm rollback onix-bap 1 && helm rollback onix-bpp 1
```

## Uninstalling

### Uninstall All Services

```bash
# Uninstall both BAP and BPP adapters
helm uninstall onix-bap onix-bpp

# Or uninstall individually
helm uninstall onix-bap && helm uninstall onix-bpp

# Remove associated resources (if needed)
kubectl delete pvc -l 'app in (onix-bap,onix-bpp)'
kubectl delete configmap -l 'app in (onix-bap,onix-bpp)'
```

### Uninstall Individual Services

```bash
# Uninstall BAP
helm uninstall onix-bap

# Uninstall BPP
helm uninstall onix-bpp

# Remove associated resources (if needed)
kubectl delete pvc -l app=onix-bap
kubectl delete configmap -l app=onix-bap
```

## Testing with Sample Messages

This section shows how to use the pre-formatted JSON test messages to test your API endpoints. Test messages are available in the `sandbox/docker/kafka/message/` directory.

### Test Messages Location

Test messages are organized by component:
- **BAP Messages**: `sandbox/docker/kafka/message/bap/example/`
- **BPP Messages**: `sandbox/docker/kafka/message/bpp/example/`

### Available Test Messages

#### BAP Test Messages (Outgoing Requests)

| Action | File | Endpoint |
|--------|------|----------|
| discover | `discover-by-station.json` | `/bap/caller/discover` |
| discover | `discover-by-evse.json` | `/bap/caller/discover` |
| discover | `discover-by-cpo.json` | `/bap/caller/discover` |
| discover | `discover-along-a-route.json` | `/bap/caller/discover` |
| discover | `discover-within-boundary.json` | `/bap/caller/discover` |
| discover | `discover-within-timerange.json` | `/bap/caller/discover` |
| discover | `discover-connector-spec.json` | `/bap/caller/discover` |
| discover | `discover-vehicle-spec.json` | `/bap/caller/discover` |
| select | `select.json` | `/bap/caller/select` |
| init | `init.json` | `/bap/caller/init` |
| confirm | `confirm.json` | `/bap/caller/confirm` |
| update | `update.json` | `/bap/caller/update` |
| track | `track.json` | `/bap/caller/track` |
| cancel | `cancel.json` | `/bap/caller/cancel` |
| rating | `rating.json` | `/bap/caller/rating` |
| support | `support.json` | `/bap/caller/support` |

#### BPP Test Messages (Outgoing Responses)

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

### Using Test Messages with curl

#### Prerequisites

1. **Port Forward Services** (if using ClusterIP):
   ```bash
   # Port forward BAP service
   kubectl port-forward svc/onix-bap-service 8001:8001 &
   
   # Port forward BPP service
   kubectl port-forward svc/onix-bpp-service 8002:8002 &
   ```

2. **Get Service URLs**:
   - If using LoadBalancer: Get external IP from `kubectl get svc`
   - If using port forwarding: Use `http://localhost:8001` (BAP) and `http://localhost:8002` (BPP)

#### Example: Send Discover Request (BAP)

```bash
# Navigate to message directory
cd sandbox/docker/kafka/message/bap/example

# Send discover request
curl -X POST http://localhost:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d @discover-by-station.json
```

**Note**: Update the `bap_uri` in the JSON file to match your BAP backend service URL before sending.

#### Example: Send Select Request (BAP)

```bash
# Update bap_uri and bpp_uri in the JSON file first
# Then send select request
curl -X POST http://localhost:8001/bap/caller/select \
  -H "Content-Type: application/json" \
  -d @select.json
```

#### Example: Send On_Discover Response (BPP)

```bash
# Navigate to BPP message directory
cd sandbox/docker/kafka/message/bpp/example

# Send on_discover response
curl -X POST http://localhost:8002/bpp/caller/on_discover \
  -H "Content-Type: application/json" \
  -d @on_discover.json
```

### Adapting Messages for API Testing

Before using the test messages, you may need to update certain fields:

1. **Update `bap_uri`**: Point to your BAP backend service
   ```json
   "bap_uri": "http://your-bap-backend:9001"
   ```

2. **Update `bpp_uri`**: Point to your BPP backend service or ONIX BPP adapter
   ```json
   "bpp_uri": "http://onix-bpp-service:8002/bpp/receiver"
   ```

3. **Update Service Names**: Use the correct Kubernetes service names:
   - Registry: `mock-registry:3030`
   - CDS: `mock-cds:8082`
   - BAP Backend: `mock-bap:9001`
   - BPP Backend: `mock-bpp:9002`
   - Redis BAP: `onix-bap-redis-bap:6379`
   - Redis BPP: `onix-bpp-redis-bpp:6379`

4. **Generate New IDs**: Update `transaction_id` and `message_id` for each request:
   ```bash
   # Generate new UUIDs
   uuidgen  # For transaction_id
   uuidgen  # For message_id
   ```

### Quick Test Script

Create a simple test script to send multiple requests:

```bash
#!/bin/bash
# test-api.sh

BAP_URL="http://localhost:8001"
BPP_URL="http://localhost:8002"
MESSAGE_DIR="sandbox/docker/kafka/message"

# Test BAP discover
echo "Testing BAP discover..."
curl -X POST ${BAP_URL}/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d @${MESSAGE_DIR}/bap/example/discover-by-station.json

# Test BAP select
echo "Testing BAP select..."
curl -X POST ${BAP_URL}/bap/caller/select \
  -H "Content-Type: application/json" \
  -d @${MESSAGE_DIR}/bap/example/select.json

# Test BPP on_discover
echo "Testing BPP on_discover..."
curl -X POST ${BPP_URL}/bpp/caller/on_discover \
  -H "Content-Type: application/json" \
  -d @${MESSAGE_DIR}/bpp/example/on_discover.json
```

### Testing from Within Kubernetes Cluster

If you want to test from within the cluster (e.g., from a pod):

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
      "bap_uri": "http://mock-bap:9001",
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

### Testing All Actions

To test all available actions, you can iterate through all JSON files:

```bash
# Test all BAP caller actions
# Note: All discover variants use the same endpoint
for file in sandbox/docker/kafka/message/bap/example/*.json; do
  filename=$(basename "$file" .json)
  # Map filename to action endpoint
  case "$filename" in
    discover-*) action="discover" ;;
    select) action="select" ;;
    init) action="init" ;;
    confirm) action="confirm" ;;
    update) action="update" ;;
    track) action="track" ;;
    cancel) action="cancel" ;;
    rating) action="rating" ;;
    support) action="support" ;;
    *) echo "Skipping unknown file: $filename"; continue ;;
  esac
  echo "Testing: $action (from $filename.json)"
  curl -X POST "http://localhost:8001/bap/caller/${action}" \
    -H "Content-Type: application/json" \
    -d @"$file"
  echo ""
done

# Test all BPP caller actions
for file in sandbox/docker/kafka/message/bpp/example/*.json; do
  filename=$(basename "$file" .json)
  # BPP files already have 'on_' prefix, use as-is
  action="$filename"
  echo "Testing: $action"
  curl -X POST "http://localhost:8002/bpp/caller/${action}" \
    -H "Content-Type: application/json" \
    -d @"$file"
  echo ""
done
```

### Message Validation

Before sending messages, validate the JSON structure:

```bash
# Validate JSON syntax
jq . sandbox/docker/kafka/message/bap/example/discover-by-station.json

# Check required fields
jq '.context | {action, domain, bap_id, bap_uri, transaction_id, message_id}' \
  sandbox/docker/kafka/message/bap/example/discover-by-station.json
```

### Additional Resources

- **Message Documentation**: See `sandbox/docker/kafka/message/bap/README.md` and `sandbox/docker/kafka/message/bpp/README.md` for detailed message documentation
- **Postman Collections**: Use the Postman collections in `api-collection/postman-collection/` for GUI-based testing
- **Swagger Documentation**: See `api-collection/swagger/` for API specifications

## Troubleshooting

### Pod Won't Start

1. **Check pod status:**
   ```bash
   kubectl get pods -l app=onix-bap
   kubectl describe pod <pod-name>
   ```

2. **Check pod logs:**
   ```bash
   kubectl logs <pod-name>
   kubectl logs <pod-name> --previous  # Previous container logs
   ```

3. **Check events:**
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

### Configuration Issues

1. **Verify ConfigMap:**
   ```bash
   kubectl get configmap onix-bap-config -o yaml
   ```

2. **Check mounted files:**
   ```bash
   kubectl exec <pod-name> -- ls -la /app/config/
   kubectl exec <pod-name> -- cat /app/config/adapter.yaml
   ```

### Redis Connection Issues

1. **Verify Redis service:**
   ```bash
   # For BAP
   kubectl get svc onix-bap-redis-bap
   kubectl get pods -l component=redis,app-component=bap
   
   # For BPP
   kubectl get svc onix-bpp-redis-bpp
   kubectl get pods -l component=redis,app-component=bpp
   ```

2. **Test connectivity:**
   ```bash
   # For BAP
   kubectl exec <pod-name> -- redis-cli -h onix-bap-redis-bap ping
   
   # For BPP
   kubectl exec <pod-name> -- redis-cli -h onix-bpp-redis-bpp ping
   ```

### Service Discovery Issues

1. **Verify service endpoints:**
   ```bash
   kubectl get endpoints onix-bap-service
   ```

2. **Test service connectivity:**
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://onix-bap-service:8001/health
   ```

## Customization

### Secret Management

The Helm chart supports secret management for production deployments:

#### Development (Hardcoded Values)

By default, secrets are disabled and hardcoded values from `config.keys` are used:

```yaml
secrets:
  enabled: false
  secretName: ""

config:
  keys:
    signingPrivateKey: "hardcoded-key"
    signingPublicKey: "hardcoded-key"
    encrPrivateKey: "hardcoded-key"
    encrPublicKey: "hardcoded-key"
```

#### Production (Kubernetes Secrets)

1. **Create Kubernetes Secret:**
   ```bash
   kubectl create secret generic onix-bap-secrets \
     --from-literal=signingPrivateKey='kaOxmZvVK0IdfMa+OtKZShKo9KVk4QLgCMn+Ch4QpU4=' \
     --from-literal=signingPublicKey='ehNGIiQxbhAJGS9U7YZN5nsUNiLDlaSUQWlWbWc4SO4=' \
     --from-literal=encrPrivateKey='kaOxmZvVK0IdfMa+OtKZShKo9KVk4QLgCMn+Ch4QpU4=' \
     --from-literal=encrPublicKey='ehNGIiQxbhAJGS9U7YZN5nsUNiLDlaSUQWlWbWc4SO4='
   ```

2. **Enable Secrets in Values:**
   ```yaml
   secrets:
     enabled: true
     secretName: "onix-bap-secrets"
   ```

3. **Deploy:**
   ```bash
   helm upgrade --install onix-bap ./helm \
     -f ./helm/values-bap.yaml \
     --set secrets.enabled=true \
     --set secrets.secretName=onix-bap-secrets
   ```

The application will read keys from environment variables (`SIGNING_PRIVATE_KEY`, etc.) which are populated from the Kubernetes Secret. If the secret doesn't exist or secrets are disabled, the hardcoded values from `config.keys` are used as fallback.

### Adding Custom Environment Variables

Edit `values.yaml`:

```yaml
env:
  - name: CUSTOM_VAR
    value: custom-value
  - name: SECRET_VAR
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: secret-key
```

### Configuring Persistent Volumes

For Redis persistence:

```yaml
redis:
  persistence:
    enabled: true
    size: 10Gi
    storageClass: standard
```

### Setting Resource Limits

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Configuration Updates

#### Schema Validator

The chart uses `schemav2validator` with URL-based schema validation:

```yaml
schemaValidator:
  id: schemav2validator
  config:
    type: url
    location: https://raw.githubusercontent.com/beckn/protocol-specifications-v2/refs/heads/core-v2.0.0-rc/api/beckn.yaml
    cacheTTL: "3600"
```

#### OTEL Plugin

OpenTelemetry metrics are enabled by default:

- **BAP**: Metrics port `9003`
- **BPP**: Metrics port `9004`

#### Routing Configuration

Routing files are mounted at:
- BAP: `/app/config/bap_caller_routing.yaml` and `/app/config/bap_receiver_routing.yaml`
- BPP: `/app/config/bpp_caller_routing.yaml` and `/app/config/bpp_receiver_routing.yaml`

#### Service Names

The chart uses simplified service names:
- Registry: `mock-registry:3030`
- CDS: `mock-cds:8082`
- BAP Backend: `mock-bap:9001`
- BPP Backend: `mock-bpp:9002`
- Redis BAP: `onix-bap-redis-bap:6379`
- Redis BPP: `onix-bpp-redis-bpp:6379`

#### BPP Application Name

BPP uses a different application name:
- BAP: `onix-ev-charging`
- BPP: `bpp-ev-charging`

## Next Steps

- For RabbitMQ integration: See [Helm RabbitMQ](../helm-rabbitmq/README.md)
- For Kafka integration: See [Helm Kafka](../helm-kafka/README.md)

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
