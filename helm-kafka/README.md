# Helm Chart - Kafka Integration (KRaft Mode)

This guide demonstrates how to deploy the **onix-adapter** using **Helm charts** with **Kafka** message broker in **KRaft mode** (no Zookeeper) on **Kubernetes**.

## Key Features

- **Kafka Integration**: Uses Kafka for async message-based communication
- **KRaft Mode**: Kafka runs without Zookeeper using KRaft consensus protocol
- **Schema Validation v2**: Uses `schemav2validator` with URL-based schema validation from Beckn protocol specifications
- **OpenTelemetry Metrics**: Built-in OTEL metrics support (port 9003 for BAP, 9004 for BPP)
- **Secret Management**: Production-ready secret management with Kubernetes Secrets and fallback to hardcoded values
- **Routing Configuration**: Flexible routing with Phase 1 (CDS aggregation) and Phase 2+ (direct routing) support
- **BAP/BPP Support**: Separate configurations for BAP and BPP adapters with component-specific settings
- **Production Ready**: Only plugin-related services deployed (no mock services)

## Architecture Overview

Deploy onix-adapter with Kafka message broker using Helm charts. In this architecture, the onix-adapter consumes and produces messages via Kafka topics for asynchronous message processing.

### Components

- **Kafka**: Message broker running in KRaft mode (no Zookeeper required)
- **Redis**: Used for caching and state management (deployed as a separate service)
- **Onix-Adapter**: BAP/BPP plugin consuming/producing messages via Kafka
- **Kafka UI**: Optional web UI for Kafka topic management and monitoring
- **Message-Based Communication**: Uses Kafka topics for async message processing

### Production Services

In production, only the following services are deployed:
- **onix-adapter** (BAP/BPP)
- **Kafka** (KRaft mode)
- **Redis**
- **Kafka UI** (optional)

**Note**: Mock services are not included in this chart. For development/sandbox environments, deploy mock services separately if needed.

## Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to onix-adapter Docker images:
  - `manendrapalsingh/onix-adapter:v0.9.3`
- Persistent volume support (for Kafka and Redis if using persistent storage)

## Directory Structure

```
helm-kafka/
├── Chart.yaml                    # Helm chart metadata
├── values.yaml                   # Default configuration values (shared Kafka infrastructure)
├── values-bap.yaml              # BAP-specific values (secrets, adapter, routing configs)
├── values-bpp.yaml              # BPP-specific values (secrets, adapter, routing configs)
├── templates/
│   ├── _helpers.tpl             # Template helpers
│   ├── deployment.yaml          # Kubernetes deployment
│   ├── service.yaml             # Kubernetes service
│   ├── configmap.yaml           # Configuration files (routing and adapter)
│   ├── redis.yaml                # Redis deployment
│   ├── kafka.yaml                # Kafka deployment (KRaft mode)
│   └── kafka-ui.yaml             # Kafka UI deployment (optional)
└── README.md                    # This file
```

### Key Features

- **Component-Specific Configs**: BAP and BPP configurations are in separate values files
- **Secrets Management**: Kubernetes Secrets support with fallback to hardcoded values
- **Kafka KRaft Mode**: No Zookeeper required
- **Routing Configuration**: Routing files mounted at `/app/config/` for easy access
- **Service Discovery**: Dynamic service name resolution based on release name

## Quick Start

### Production Deployment

#### 1. Create Kubernetes Secrets

Before deploying, create Kubernetes secrets for sensitive data:

**For BAP:**
```bash
kubectl create secret generic onix-bap-kafka-secrets \
  --from-literal=signingPrivateKey=... \
  --from-literal=signingPublicKey=... \
  --from-literal=encrPrivateKey=... \
  --from-literal=encrPublicKey=... \
  --from-literal=subscriberId=ev-charging.sandbox1.com \
  --from-literal=networkParticipant=ev-charging.sandbox1.com \
  --from-literal=keyId=bap-key-1 \
  --from-literal=redisPassword=your-redis-password
```

**For BPP:**
```bash
kubectl create secret generic onix-bpp-kafka-secrets \
  --from-literal=signingPrivateKey=... \
  --from-literal=signingPublicKey=... \
  --from-literal=encrPrivateKey=... \
  --from-literal=encrPublicKey=... \
  --from-literal=subscriberId=ev-charging.sandbox2.com \
  --from-literal=networkParticipant=ev-charging.sandbox2.com \
  --from-literal=keyId=bpp-key-1 \
  --from-literal=redisPassword=your-redis-password
```

#### 2. Deploy BAP Adapter with Kafka

```bash
# Navigate to the helm chart directory
cd helm-kafka

# Deploy BAP adapter with secrets enabled
helm upgrade --install onix-bap-kafka . \
  -f values-bap.yaml \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bap-kafka-secrets

# Check deployment status
kubectl get pods -l component=bap
kubectl get svc -l component=bap
```

#### 3. Deploy BPP Adapter (shares Kafka from BAP)

```bash
# Deploy BPP adapter (Kafka is shared from BAP release)
helm upgrade --install onix-bpp-kafka . \
  -f values-bpp.yaml \
  --set secrets.enabled=true \
  --set secrets.secretName=onix-bpp-kafka-secrets \
  --set kafka.enabled=false

# Check deployment status
kubectl get pods -l component=bpp
kubectl get svc -l component=bpp
```

### Development Deployment (with hardcoded values)

For development/testing, you can use hardcoded values from the values files:

```bash
# Deploy BAP adapter with hardcoded values (secrets disabled)
helm upgrade --install onix-bap-kafka . \
  -f values-bap.yaml \
  --set secrets.enabled=false

# Deploy BPP adapter with hardcoded values
helm upgrade --install onix-bpp-kafka . \
  -f values-bpp.yaml \
  --set secrets.enabled=false \
  --set kafka.enabled=false
```

## Configuration

### Component-Specific Configuration

The chart follows a structure similar to `helm/` where component-specific configurations are in separate files:

- **values.yaml**: Shared Kafka infrastructure (Kafka, Redis, Kafka UI)
- **values-bap.yaml**: BAP-specific configuration (secrets, adapter config, routing)
- **values-bpp.yaml**: BPP-specific configuration (secrets, adapter config, routing)

### Kafka KRaft Mode

The chart configures Kafka to run in KRaft mode (no Zookeeper):

```yaml
kafka:
  enabled: true
  processRoles: "broker,controller"
  service:
    port: 9092
    targetPort: 9092
    controllerPort: 9093

kraft:
  enabled: true
  nodeId: 1
  clusterId: MkU3OEVBNTcwNTJENDM2Qk
```

### Secret Management

#### Production (Kubernetes Secrets)

```yaml
secrets:
  enabled: true
  secretName: "onix-bap-kafka-secrets"  # or "onix-bpp-kafka-secrets"
```

#### Development (Hardcoded Values)

```yaml
secrets:
  enabled: false

config:
  keys:
    signingPrivateKey: "..."  # Hardcoded for dev only
    signingPublicKey: "..."   # Hardcoded for dev only
    # ... other keys
```

### Kafka Topics

The adapter automatically creates Kafka topics based on the configuration:

**BAP Topics:**
- Consumer: `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
- Publisher: `bap.on_discover`, `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support`, `bap.on_default`

**BPP Topics:**
- Consumer: `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`
- Publisher: `bpp.discover`, `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support`, `bpp.default`

### Service Endpoints

Once deployed, services are accessible via Kubernetes services:

- **Kafka Broker**: `<release-name>-onix-kafka-kafka:9092`
- **Kafka Controller**: `<release-name>-onix-kafka-kafka:9093`
- **Redis**: `<release-name>-onix-kafka-redis-<component>:6379`
- **BAP Service**: `<release-name>-onix-kafka-bap:8001`
- **BPP Service**: `<release-name>-onix-kafka-bpp:8002`
- **Kafka UI** (if enabled): `<release-name>-onix-kafka-kafka-ui:8080`

## Configuration Files

### Adapter Configuration

The adapter configuration is defined in component-specific values files:

- **BAP**: `values-bap.yaml` → `config.adapter`
- **BPP**: `values-bpp.yaml` → `config.adapter`

Key settings:
- `appName`: "onix-ev-charging" (BAP) or "bpp-ev-charging" (BPP)
- `http.port`: 8001 (BAP) or 8002 (BPP)
- `plugins.otelsetup.config.metricsPort`: "9003" (BAP) or "9004" (BPP)

### Routing Configuration

Routing configurations are also in component-specific values files:

- **BAP**: `values-bap.yaml` → `config.routing.caller` and `config.routing.receiver`
- **BPP**: `values-bpp.yaml` → `config.routing.caller` and `config.routing.receiver`

Routing files are mounted at:
- `/app/config/bapTxnCaller-routing.yaml` (BAP) or `/app/config/bppTxnCaller-routing.yaml` (BPP)
- `/app/config/bapTxnReciever-routing.yaml` (BAP) or `/app/config/bppTxnReciever-routing.yaml` (BPP)

## Advanced Configuration

### Using External Kafka

If you want to use an external Kafka cluster instead of deploying one:

```yaml
kafka:
  enabled: false
  broker: "external-kafka:9092"  # External Kafka broker address
```

### Using External Redis

If you want to use an external Redis instance:

```yaml
redis:
  enabled: false
  host: "external-redis:6379"  # External Redis address
```

### Customizing Resource Limits

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Enabling Kafka UI

Kafka UI is disabled by default. To enable it:

```yaml
kafkaUI:
  enabled: true
```

Or override during deployment:

```bash
helm upgrade --install onix-bap-kafka . \
  -f values-bap.yaml \
  --set kafkaUI.enabled=true
```

## Monitoring and Logs

### View Pod Logs

```bash
# BAP adapter logs
kubectl logs -l component=bap -f

# BPP adapter logs
kubectl logs -l component=bpp -f

# Kafka logs
kubectl logs -l app=onix-kafka-kafka -f

# Redis logs
kubectl logs -l app=onix-kafka-redis -f
```

### Check Pod Status

```bash
# All pods
kubectl get pods -l 'app in (onix-kafka-bap,onix-kafka-bpp,onix-kafka-kafka,onix-kafka-redis)'

# By component
kubectl get pods -l component=bap
kubectl get pods -l component=bpp
```

### Access Kafka UI

If Kafka UI is enabled, port-forward to access it:

```bash
kubectl port-forward svc/<release-name>-onix-kafka-kafka-ui 8080:8080
```

Then open `http://localhost:8080` in your browser.

## Upgrading

```bash
# Upgrade BAP adapter
helm upgrade onix-bap-kafka . -f values-bap.yaml

# Upgrade BPP adapter
helm upgrade onix-bpp-kafka . -f values-bpp.yaml
```

## Uninstalling

```bash
# Uninstall BAP adapter
helm uninstall onix-bap-kafka

# Uninstall BPP adapter
helm uninstall onix-bpp-kafka

# Note: If Kafka was deployed with BAP, it will be removed when BAP is uninstalled
```

## Troubleshooting

### Pods Not Starting

1. Check pod status:
   ```bash
   kubectl describe pod <pod-name>
   ```

2. Check logs:
   ```bash
   kubectl logs <pod-name>
   ```

3. Verify secrets exist (if using secrets):
   ```bash
   kubectl get secret onix-bap-kafka-secrets
   ```

### Kafka Connection Issues

1. Verify Kafka is running:
   ```bash
   kubectl get pods -l app=onix-kafka-kafka
   ```

2. Check Kafka service:
   ```bash
   kubectl get svc -l app=onix-kafka-kafka
   ```

3. Test Kafka connectivity from adapter pod:
   ```bash
   kubectl exec -it <adapter-pod> -- nc -zv <kafka-service> 9092
   ```

### Redis Connection Issues

1. Verify Redis is running:
   ```bash
   kubectl get pods -l app=onix-kafka-redis
   ```

2. Check Redis service:
   ```bash
   kubectl get svc -l app=onix-kafka-redis
   ```

3. Test Redis connectivity:
   ```bash
   kubectl exec -it <adapter-pod> -- redis-cli -h <redis-service> -p 6379 -a <password> ping
   ```

## Differences from helm/ Chart

The `helm-kafka/` chart differs from `helm/` in the following ways:

1. **Message Broker**: Uses Kafka instead of direct HTTP/REST API
2. **Communication**: Async message-based via Kafka topics instead of synchronous HTTP
3. **Kafka Infrastructure**: Includes Kafka deployment (KRaft mode) and optional Kafka UI
4. **No Mock Services**: Mock services are not included (deploy separately if needed)
5. **Queue Handlers**: BAP/BPP caller modules use `type: queue` instead of `type: std`
6. **Publisher/Consumer**: Uses Kafka publisher and consumer plugins

## Additional Resources

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [KRaft Mode](https://kafka.apache.org/documentation/#kraft)
- [ONIX Adapter Documentation](../onix-adaptor-kafka/README.md)
