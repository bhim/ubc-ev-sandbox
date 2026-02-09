# ONIX BAP RabbitMQ Helm Chart

A Helm chart for deploying the ONIX BAP (Buyer App Provider) adapter with RabbitMQ message broker.

## Installation

### From Git Repository

```bash
# Install BAP RabbitMQ chart
helm install onix-bap-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-rabbitmq

# Or from a specific branch/tag
helm install onix-bap-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-rabbitmq?ref=main
```

### With External RabbitMQ and Redis

```bash
helm install onix-bap-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-rabbitmq \
  --set rabbitmq.broker=external-rabbitmq:5672 \
  --set rabbitmq.username=admin \
  --set rabbitmq.password=admin \
  --set redis.host=external-redis:6379 \
  --set redis.password=your-password
```

## Configuration

### Required Configuration

- **RabbitMQ Broker**: Configure external RabbitMQ instance
  ```yaml
  rabbitmq:
    broker: "rabbitmq-service:5672"  # REQUIRED: Your RabbitMQ broker host:port
    username: "admin"  # RabbitMQ username
    password: "admin"  # RabbitMQ password
  ```

- **Redis Host**: Configure external Redis instance
  ```yaml
  redis:
    host: "redis-service:6379"  # REQUIRED: Your Redis host:port
    password: ""  # Optional: Redis password if required
  ```

### Optional Configuration

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
| `rabbitmq.broker` | External RabbitMQ broker host:port | `""` (REQUIRED) |
| `rabbitmq.username` | RabbitMQ username | `"admin"` |
| `rabbitmq.password` | RabbitMQ password | `"admin"` |
| `redis.host` | External Redis host:port | `""` (REQUIRED) |
| `redis.password` | Redis password | `""` |
| `image.repository` | Container image repository | `manendrapalsingh/onix-adapter` |
| `image.tag` | Container image tag | `v0.9.3` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `8001` |

## External Services

This chart does NOT deploy RabbitMQ or Redis. You must provide external instances and configure them using:
- `rabbitmq.broker` for RabbitMQ
- `redis.host` for Redis

## Examples

### Basic Installation

```bash
helm install onix-bap-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-rabbitmq \
  --set rabbitmq.broker=my-rabbitmq:5672 \
  --set rabbitmq.username=admin \
  --set rabbitmq.password=admin \
  --set redis.host=my-redis:6379
```

## Service Endpoints

Once deployed, the BAP adapter is accessible at:

- **Service Name**: `<release-name>-service`
- **Port**: `8001`
- **Receiver Endpoint**: `http://<service-name>:8001/bap/receiver/{action}` (receives HTTP, publishes to RabbitMQ)

## RabbitMQ Exchange and Queues

The adapter uses:
- **Exchange**: `beckn_exchange` (durable)
- **Queue**: `bap_caller_queue` (consumes from)
- **Routing Keys**: `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`

## Uninstalling

```bash
helm uninstall onix-bap-rabbitmq
```
