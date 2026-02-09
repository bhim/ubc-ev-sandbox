# ONIX BPP Kafka Helm Chart

A Helm chart for deploying the ONIX BPP (Buyer Platform Provider) adapter with Kafka message broker.

## Installation

### From Git Repository

```bash
# Install BPP Kafka chart
helm install onix-bpp-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-kafka

# Or from a specific branch/tag
helm install onix-bpp-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-kafka?ref=main
```

### With External Kafka and Redis

```bash
helm install onix-bpp-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-kafka \
  --set kafka.broker=external-kafka:9092 \
  --set redis.host=external-redis:6379 \
  --set redis.password=your-password
```

## Configuration

### Required Configuration

- **Kafka Broker**: Configure external Kafka instance
  ```yaml
  kafka:
    broker: "kafka-service:9092"  # REQUIRED: Your Kafka broker host:port
  ```

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
    secretName: "onix-bpp-kafka-secrets"
  ```

- **Service Type**: Change service type (ClusterIP, NodePort, LoadBalancer)
  ```yaml
  service:
    type: LoadBalancer
    port: 8002
  ```

## Values

Key configuration values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kafka.broker` | External Kafka broker host:port | `""` (REQUIRED) |
| `redis.host` | External Redis host:port | `""` (REQUIRED) |
| `redis.password` | Redis password | `""` |
| `image.repository` | Container image repository | `manendrapalsingh/onix-adapter` |
| `image.tag` | Container image tag | `v0.9.3` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `8002` |
| `secrets.enabled` | Enable Kubernetes secrets | `false` |
| `secrets.secretName` | Kubernetes secret name | `""` |

## External Services

This chart does NOT deploy Kafka or Redis. You must provide external instances and configure them using:
- `kafka.broker` for Kafka
- `redis.host` for Redis

## Examples

### Basic Installation

```bash
helm install onix-bpp-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-kafka \
  --set kafka.broker=my-kafka:9092 \
  --set redis.host=my-redis:6379
```

### Production Installation with Secrets

```bash
# Create secret first
kubectl create secret generic onix-bpp-kafka-secrets \
  --from-literal=signingPrivateKey='...' \
  --from-literal=signingPublicKey='...' \
  --from-literal=encrPrivateKey='...' \
  --from-literal=encrPublicKey='...' \
  --from-literal=subscriberId='...' \
  --from-literal=networkParticipant='...' \
  --from-literal=keyId='...' \
  --from-literal=redisPassword='...'

# Install with secrets
helm install onix-bpp-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-kafka \
  --set kafka.broker=kafka-service:9092 \
  --set redis.host=redis-service:6379 \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bpp-kafka-secrets
```

## Service Endpoints

Once deployed, the BPP adapter is accessible at:

- **Service Name**: `<release-name>-service`
- **Port**: `8002`
- **Receiver Endpoint**: `http://<service-name>:8002/bpp/receiver/{action}` (receives HTTP, publishes to Kafka)

## Kafka Topics

The adapter uses the following Kafka topics:

**Consumer Topics** (BPP Caller reads from):
- `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`

**Publisher Topics** (BPP Receiver publishes to):
- `bpp.discover`, `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support`, `bpp.default`

## Uninstalling

```bash
helm uninstall onix-bpp-kafka
```
