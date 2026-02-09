# ONIX Helm Charts

This directory contains standalone Helm charts for deploying ONIX adapters (BAP and BPP) that can be installed directly from Git. These charts deploy only the ONIX adapter components and require external infrastructure services (Redis, Kafka, RabbitMQ) to be configured separately.

## Available Charts

| Chart | Description | Communication | Port |
|-------|-------------|---------------|------|
| [`bap`](./bap/) | ONIX BAP adapter (REST API) | HTTP/REST | 8001 |
| [`bpp`](./bpp/) | ONIX BPP adapter (REST API) | HTTP/REST | 8002 |
| [`bap-kafka`](./bap-kafka/) | ONIX BAP adapter with Kafka | Kafka + HTTP | 8001 |
| [`bpp-kafka`](./bpp-kafka/) | ONIX BPP adapter with Kafka | Kafka + HTTP | 8002 |
| [`bap-rabbitmq`](./bap-rabbitmq/) | ONIX BAP adapter with RabbitMQ | RabbitMQ + HTTP | 8001 |
| [`bpp-rabbitmq`](./bpp-rabbitmq/) | ONIX BPP adapter with RabbitMQ | RabbitMQ + HTTP | 8002 |

## Quick Start

### Install from Git Repository

The charts are available from the repository: `https://github.com/bhim/ubc-ev-sandbox`

#### REST API Charts (BAP/BPP)

```bash
# Install BAP chart
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap \
  --set redis.host=redis-service:6379

# Install BPP chart
helm install onix-bpp https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp \
  --set redis.host=redis-service:6379
```

#### Kafka Charts

```bash
# Install BAP Kafka chart
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka \
  --set kafka.broker=kafka-service:9092 \
  --set redis.host=redis-service:6379

# Install BPP Kafka chart
helm install onix-bpp-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-kafka \
  --set kafka.broker=kafka-service:9092 \
  --set redis.host=redis-service:6379
```

#### RabbitMQ Charts

```bash
# Install BAP RabbitMQ chart
helm install onix-bap-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-rabbitmq \
  --set rabbitmq.broker=rabbitmq-service:5672 \
  --set rabbitmq.username=admin \
  --set rabbitmq.password=admin \
  --set redis.host=redis-service:6379

# Install BPP RabbitMQ chart
helm install onix-bpp-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bpp-rabbitmq \
  --set rabbitmq.broker=rabbitmq-service:5672 \
  --set rabbitmq.username=admin \
  --set rabbitmq.password=admin \
  --set redis.host=redis-service:6379
```

### Install from Specific Branch/Tag

```bash
# Install from main branch
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap?ref=main

# Install from specific tag
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap?ref=v1.0.0
```

## Chart Details

### REST API Charts (`bap` / `bpp`)

- **Communication**: Direct HTTP/REST API
- **External Services Required**: Redis (for caching)
- **Use Case**: Simple deployments with direct HTTP communication

**Installation Example:**
```bash
helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap \
  --set redis.host=my-redis:6379
```

See individual chart READMEs:
- [BAP Chart README](./bap/README.md)
- [BPP Chart README](./bpp/README.md)

### Kafka Charts (`bap-kafka` / `bpp-kafka`)

- **Communication**: Kafka message broker + HTTP (for receiver)
- **External Services Required**: Kafka, Redis
- **Use Case**: Asynchronous message-based communication

**Installation Example:**
```bash
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka \
  --set kafka.broker=kafka:9092 \
  --set redis.host=redis:6379
```

See individual chart READMEs:
- [BAP Kafka Chart README](./bap-kafka/README.md)
- [BPP Kafka Chart README](./bpp-kafka/README.md)

### RabbitMQ Charts (`bap-rabbitmq` / `bpp-rabbitmq`)

- **Communication**: RabbitMQ message broker + HTTP (for receiver)
- **External Services Required**: RabbitMQ, Redis
- **Use Case**: Asynchronous message-based communication with RabbitMQ

**Installation Example:**
```bash
helm install onix-bap-rabbitmq https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-rabbitmq \
  --set rabbitmq.broker=rabbitmq:5672 \
  --set rabbitmq.username=admin \
  --set rabbitmq.password=admin \
  --set redis.host=redis:6379
```

See individual chart READMEs:
- [BAP RabbitMQ Chart README](./bap-rabbitmq/README.md)
- [BPP RabbitMQ Chart README](./bpp-rabbitmq/README.md)

## Key Features

- **No Infrastructure Deployment**: Charts deploy only the ONIX adapter, not Redis/Kafka/RabbitMQ
- **External Service Configuration**: Configure external services via values.yaml or --set flags
- **Production Ready**: Support for Kubernetes secrets for sensitive data
- **Git-Based Installation**: Install directly from Git repository URLs
- **Separate Charts**: Each component (BAP/BPP) has its own dedicated chart

## Required External Services

All charts require external infrastructure services to be configured:

| Service | Charts Using It | Configuration Parameter |
|---------|----------------|-------------------------|
| **Redis** | All charts | `redis.host` (e.g., "redis:6379") |
| **Kafka** | `bap-kafka`, `bpp-kafka` | `kafka.broker` (e.g., "kafka:9092") |
| **RabbitMQ** | `bap-rabbitmq`, `bpp-rabbitmq` | `rabbitmq.broker` (e.g., "rabbitmq:5672") |

## Configuration

### Common Configuration

All charts support configuration via:
- **values.yaml**: Default values in each chart
- **--set flags**: Override values during installation
- **Custom values file**: Create your own values file and use `-f` flag

### Example: Custom Values File

Create `my-values.yaml`:
```yaml
redis:
  host: "my-redis:6379"
  password: "my-password"

kafka:
  broker: "my-kafka:9092"

service:
  type: LoadBalancer
```

Install with custom values:
```bash
helm install onix-bap-kafka https://github.com/bhim/ubc-ev-sandbox.git/charts/bap-kafka \
  -f my-values.yaml
```

## Production Deployment

### Using Kubernetes Secrets

1. **Create secrets:**
   ```bash
   kubectl create secret generic onix-bap-secrets \
     --from-literal=signingPrivateKey='...' \
     --from-literal=signingPublicKey='...' \
     --from-literal=encrPrivateKey='...' \
     --from-literal=encrPublicKey='...'
   ```

2. **Install with secrets:**
   ```bash
   helm install onix-bap https://github.com/bhim/ubc-ev-sandbox.git/charts/bap \
     --set redis.host=redis-service:6379 \
     --set secrets.enabled=true \
     --set secrets.secretName=onix-bap-secrets
   ```

## Service Endpoints

After deployment, services are accessible via Kubernetes services:

| Chart | Service Port | Caller Endpoint | Receiver Endpoint |
|-------|--------------|-----------------|-------------------|
| `bap` | 8001 | `http://<service>:8001/bap/caller/{action}` | `http://<service>:8001/bap/receiver/{action}` |
| `bpp` | 8002 | `http://<service>:8002/bpp/caller/{action}` | `http://<service>:8002/bpp/receiver/{action}` |
| `bap-kafka` | 8001 | (Kafka topics) | `http://<service>:8001/bap/receiver/{action}` |
| `bpp-kafka` | 8002 | (Kafka topics) | `http://<service>:8002/bpp/receiver/{action}` |
| `bap-rabbitmq` | 8001 | (RabbitMQ queues) | `http://<service>:8001/bap/receiver/{action}` |
| `bpp-rabbitmq` | 8002 | (RabbitMQ queues) | `http://<service>:8002/bpp/receiver/{action}` |

## Uninstalling

```bash
# Uninstall individual charts
helm uninstall onix-bap
helm uninstall onix-bpp
helm uninstall onix-bap-kafka
helm uninstall onix-bpp-kafka
helm uninstall onix-bap-rabbitmq
helm uninstall onix-bpp-rabbitmq
```

## Chart Structure

Each chart follows this structure:

```
charts/
├── <chart-name>/
│   ├── Chart.yaml          # Chart metadata
│   ├── values.yaml         # Default values
│   ├── README.md           # Chart-specific documentation
│   └── templates/
│       ├── _helpers.tpl    # Template helpers
│       ├── deployment.yaml # ONIX adapter deployment
│       ├── service.yaml    # Kubernetes service
│       └── configmap.yaml  # Configuration files
```

## Differences from Monolithic Charts

These charts differ from the monolithic charts (`helm/`, `helm-kafka/`, `helm-rabbitmq/`) in the following ways:

1. **No Infrastructure**: Do not deploy Redis, Kafka, or RabbitMQ
2. **Component-Specific**: Each chart is hardcoded for BAP or BPP (no `component` parameter)
3. **External Services**: Require external service configuration
4. **Simplified**: Fewer templates, focused on adapter deployment only

## Troubleshooting

### Service Connection Issues

If the adapter cannot connect to external services:

1. **Verify service addresses:**
   ```bash
   # Check Redis
   kubectl get svc redis-service
   
   # Check Kafka
   kubectl get svc kafka-service
   
   # Check RabbitMQ
   kubectl get svc rabbitmq-service
   ```

2. **Test connectivity from adapter pod:**
   ```bash
   kubectl exec -it <adapter-pod> -- nc -zv <service-host> <port>
   ```

3. **Check adapter logs:**
   ```bash
   kubectl logs <adapter-pod>
   ```

### Configuration Issues

1. **Verify ConfigMap:**
   ```bash
   kubectl get configmap <release-name>-config -o yaml
   ```

2. **Check environment variables:**
   ```bash
   kubectl exec <adapter-pod> -- env | grep -E "REDIS|KAFKA|RABBITMQ"
   ```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Helm Documentation](https://helm.sh/docs/)

## Contributing

When contributing to these charts:

1. Ensure external service configuration is properly documented
2. Update README.md with any new configuration options
3. Test installation from Git URL
4. Verify external service connectivity works correctly
