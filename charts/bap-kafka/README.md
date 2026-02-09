# ONIX BAP Kafka Helm Chart

A Helm chart for deploying the ONIX BAP (Buyer App Provider) adapter with Kafka message broker.

## Installation

### From Git Repository

```bash
# Install BAP Kafka chart
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka

# Or from a specific branch/tag
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka?ref=main
```

### With External Kafka and Redis

```bash
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka \
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
    secretName: "onix-bap-kafka-secrets"
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
| `kafka.broker` | External Kafka broker host:port | `""` (REQUIRED) |
| `redis.host` | External Redis host:port | `""` (REQUIRED) |
| `redis.password` | Redis password | `""` |
| `image.repository` | Container image repository | `manendrapalsingh/onix-adapter` |
| `image.tag` | Container image tag | `v0.9.3` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `8001` |
| `secrets.enabled` | Enable Kubernetes secrets | `false` |
| `secrets.secretName` | Kubernetes secret name | `""` |

## External Services

This chart does NOT deploy Kafka or Redis. You must provide external instances and configure them using:
- `kafka.broker` for Kafka
- `redis.host` for Redis

## Examples

### Basic Installation

```bash
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka \
  --set kafka.broker=my-kafka:9092 \
  --set redis.host=my-redis:6379
```

### Production Installation with Secrets

```bash
# Create secret first
kubectl create secret generic onix-bap-kafka-secrets \
  --from-literal=signingPrivateKey='...' \
  --from-literal=signingPublicKey='...' \
  --from-literal=encrPrivateKey='...' \
  --from-literal=encrPublicKey='...' \
  --from-literal=subscriberId='...' \
  --from-literal=networkParticipant='...' \
  --from-literal=keyId='...' \
  --from-literal=redisPassword='...'

# Install with secrets
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka \
  --set kafka.broker=kafka-service:9092 \
  --set redis.host=redis-service:6379 \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bap-kafka-secrets
```

## Service Endpoints

Once deployed, the BAP adapter is accessible at:

- **Service Name**: `<release-name>-service`
- **Port**: `8001`
- **Receiver Endpoint**: `http://<service-name>:8001/bap/receiver/{action}` (receives HTTP, publishes to Kafka)

## Kafka Topics

The adapter uses the following Kafka topics:

**Consumer Topics** (BAP Caller reads from):
- `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`

**Publisher Topics** (BAP Receiver publishes to):
- `bap.on_discover`, `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support`, `bap.on_default`

## Uninstalling

```bash
helm uninstall onix-bap-kafka
```
