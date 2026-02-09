# ONIX BAP Helm Chart

A Helm chart for deploying the ONIX BAP (Buyer App Provider) adapter using REST API communication.

## Installation

### From Git Repository

```bash
# Install BAP chart
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap

# Or from a specific branch/tag
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap?ref=main
```

### With External Redis

```bash
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap \
  --set redis.host=external-redis:6379 \
  --set redis.password=your-password
```

## Configuration

### Required Configuration

- **Redis Host**: Configure external Redis instance
  ```yaml
  redis:
    host: "redis-service:6379"  # REQUIRED: Your Redis host:port
    password: ""  # Optional: Redis password if required
  ```

### Optional Configuration

- **Secrets**: Enable Kubernetes secrets for production
  ```yaml
  secrets:
    enabled: true
    secretName: "onix-bap-secrets"
  ```

- **Service Type**: Change service type (ClusterIP, NodePort, LoadBalancer)
  ```yaml
  service:
    type: LoadBalancer
    port: 8001
  ```

## Values

Key configuration values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.host` | External Redis host:port | `""` (REQUIRED) |
| `redis.password` | Redis password | `""` |
| `image.repository` | Container image repository | `manendrapalsingh/onix-adapter` |
| `image.tag` | Container image tag | `v0.9.3` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `8001` |
| `secrets.enabled` | Enable Kubernetes secrets | `false` |
| `secrets.secretName` | Kubernetes secret name | `""` |

## External Services

This chart does NOT deploy Redis. You must provide an external Redis instance and configure it using the `redis.host` value.

## Examples

### Basic Installation

```bash
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap \
  --set redis.host=my-redis:6379
```

### Production Installation with Secrets

```bash
# Create secret first
kubectl create secret generic onix-bap-secrets \
  --from-literal=signingPrivateKey='...' \
  --from-literal=signingPublicKey='...' \
  --from-literal=encrPrivateKey='...' \
  --from-literal=encrPublicKey='...'

# Install with secrets
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap \
  --set redis.host=redis-service:6379 \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bap-secrets
```

## Service Endpoints

Once deployed, the BAP adapter is accessible at:

- **Service Name**: `<release-name>-service`
- **Port**: `8001`
- **Caller Endpoint**: `http://<service-name>:8001/bap/caller/{action}`
- **Receiver Endpoint**: `http://<service-name>:8001/bap/receiver/{action}`

## Uninstalling

```bash
helm uninstall onix-bap
```
