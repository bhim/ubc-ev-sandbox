# Helm Chart - Microservice Architecture - API Integration

This guide demonstrates how to deploy the **onix-adapter** using **Helm charts** in a **microservice architecture** with **REST API** communication on **Kubernetes**.

## Architecture Overview

Deploy onix-adapter in a microservice architecture on Kubernetes using Helm charts. In this architecture, a single adapter service handles all endpoints, but each endpoint is configured to route to different services. This allows for centralized management with flexible routing.

### Components

- **Redis**: Shared caching service for each adapter
- **Onix-Adapter Services**: Single BAP and BPP service handling all endpoints
- **API Communication**: Direct HTTP/REST API calls between services
- **Kubernetes Services**: Service objects for service discovery and load balancing
- **Endpoint-Based Routing**: Each endpoint routes to different backend services

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
helm/api/microservice/
├── Chart.yaml                    # Helm chart metadata
├── values.yaml                   # Default configuration values
├── values-bap.yaml              # BAP-specific values
├── values-bpp.yaml              # BPP-specific values
├── templates/
│   ├── deployment.yaml          # Kubernetes deployment
│   ├── service.yaml             # Kubernetes service
│   ├── configmap.yaml           # Configuration files
│   ├── secret.yaml              # Secrets (if needed)
│   └── redis/                   # Redis deployment (optional)
│       ├── deployment.yaml
│       └── service.yaml
└── README.md                    # This file
```

## Quick Start

### Install BAP Adapter

```bash
# Install with default values
helm install onix-bap ./helm/api/microservice -f ./helm/api/microservice/values-bap.yaml

# Or install with custom values
helm install onix-bap ./helm/api/microservice -f ./helm/api/microservice/values-bap.yaml --set image.tag=v1.0.0
```

### Install BPP Adapter

```bash
# Install with default values
helm install onix-bpp ./helm/api/microservice -f ./helm/api/microservice/values-bpp.yaml

# Or install with custom values
helm install onix-bpp ./helm/api/microservice -f ./helm/api/microservice/values-bpp.yaml --set image.tag=v1.0.0
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

#### Adapter Configuration (Microservice Routing)

```yaml
config:
  adapter:
    # Adapter configuration (mounted as ConfigMap)
    appName: onix-ev-charging
    http:
      port: 8001
  routing:
    # Microservice routing configuration
    # Each endpoint routes to different services
    caller: |
      routingRules:
        - domain: "ev_charging_network"
          version: "1.0.0"
          endpoints:
            discover:
              target:
                type: url
                url: "http://ev-charging-mock-cds:8082/csd"
            select:
              target:
                type: url
                url: "http://ev-charging-bpp-onix-api-microservice-bpp-service:8002/bpp/receiver/select"
            # ... other endpoints
    receiver: |
      routingRules:
        - domain: "ev_charging_network"
          version: "1.0.0"
          endpoints:
            on_discover:
              target:
                type: url
                url: "http://ev-charging-mock-bap-on-discover:9001"
            on_select:
              target:
                type: url
                url: "http://ev-charging-mock-bap-on-select:9002"
            # ... other endpoints
```

### Environment Variables

```yaml
env:
  - name: CONFIG_FILE
    value: /app/config/adapter.yaml
  - name: LOG_LEVEL
    value: info
```

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
helm install onix-bap ./helm/api/microservice \
  -f ./helm/api/microservice/values-bap.yaml \
  --set redis.enabled=true
```

### Option 2: Deploy with External Redis

Use an existing Redis instance:

```bash
helm install onix-bap ./helm/api/microservice \
  -f ./helm/api/microservice/values-bap.yaml \
  --set redis.enabled=false \
  --set config.redis.host=external-redis-service \
  --set config.redis.port=6379
```

### Option 3: Deploy with Custom Routing

Override routing configuration for microservice architecture:

```bash
helm install onix-bap ./helm/api/microservice \
  -f ./helm/api/microservice/values-bap.yaml \
  --set-file config.routing.caller=./custom-caller-routing.yaml \
  --set-file config.routing.receiver=./custom-receiver-routing.yaml
```

## Service Endpoints

Once deployed, the services are accessible via Kubernetes services:

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

### Microservice Routing

In microservice architecture, each endpoint routes to different backend services:

- **BAP Caller**: Routes to different BPP services based on action
- **BAP Receiver**: Routes to different BAP backend services based on callback
- **BPP Caller**: Routes to different BAP services based on response
- **BPP Receiver**: Routes to different BPP backend services based on request

## Upgrading

### Upgrade Release

```bash
# Upgrade with new values
helm upgrade onix-bap ./helm/api/microservice \
  -f ./helm/api/microservice/values-bap.yaml \
  --set image.tag=v1.1.0

# Check upgrade status
helm status onix-bap
```

### Rollback

```bash
# List release history
helm history onix-bap

# Rollback to previous version
helm rollback onix-bap 1
```

## Uninstalling

```bash
# Uninstall BAP
helm uninstall onix-bap

# Uninstall BPP
helm uninstall onix-bpp

# Remove associated resources (if needed)
kubectl delete pvc -l app=onix-bap
```

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

### Routing Issues

1. **Verify routing configuration:**
   ```bash
   kubectl exec <pod-name> -- cat /app/config/onix-bap/bap_caller_routing.yaml
   kubectl exec <pod-name> -- cat /app/config/onix-bap/bap_receiver_routing.yaml
   ```

2. **Check backend service connectivity:**
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://ev-charging-mock-bap-on-select:9002/health
   ```

### Redis Connection Issues

1. **Verify Redis service:**
   ```bash
   kubectl get svc redis-onix-bap
   kubectl get pods -l app=redis-onix-bap
   ```

2. **Test connectivity:**
   ```bash
   kubectl exec <pod-name> -- redis-cli -h redis-onix-bap ping
   ```

## Customization

### Configuring Microservice Routing

Edit routing configuration in `values.yaml`:

```yaml
config:
  routing:
    caller: |
      routingRules:
        - domain: "ev_charging_network"
          version: "1.0.0"
          endpoints:
            select:
              target:
                type: url
                url: "http://service-select:9002"
            init:
              target:
                type: url
                url: "http://service-init:9002"
```

### Adding Custom Environment Variables

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

## Next Steps

- For RabbitMQ integration: See [Helm RabbitMQ](./../../rabbitmq/README.md)
- For Kafka integration: See [Helm Kafka](./../../kafka/README.md)
- For monolithic architecture: See [Helm Monolithic API](./../monolithic/README.md)

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
