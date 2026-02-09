# EV Charging Sandbox - Kafka Helm Setup

This directory contains Helm values files for deploying a complete EV Charging sandbox environment using Kubernetes/Helm with Kafka message broker integration. The setup includes ONIX adapters (BAP and BPP), mock services (CDS, Registry, BAP-Kafka, BPP-Kafka), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol with Kafka for asynchronous message processing. The architecture includes:

- **ONIX Kafka Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider) that consume and publish messages via Kafka
- **Mock Services**: Simulated services for testing without real implementations
- **Kafka Message Broker**: Central message broker for asynchronous communication (KRaft mode - no Zookeeper needed)
- **Supporting Services**: Redis for caching and state management
- **Kafka UI**: Web UI for managing and monitoring Kafka

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to Docker images (pulled automatically from Docker Hub)
- Sufficient cluster resources for Kafka (recommended: 2GB+ memory per node)

## Quick Start

### Deploy Complete Sandbox Environment (All Services)

Deploy the complete Kafka sandbox environment with all services (BAP, BPP, Kafka, and all mock services) in one go:

**🚀 Quick Deploy - All Services**

**Option 1: Using the Deployment Script (Recommended)**

The easiest way to deploy all services is using the provided script:

```bash
# Run from helm-sandbox-kafka directory
cd helm-sandbox-kafka
./deploy-all.sh
```

The script automatically:
- Verifies all paths exist
- Checks Kubernetes cluster connectivity
- Creates the namespace if needed
- Deploys BAP and BPP adapters (with Kafka, Kafka UI, Redis)
- Deploys Mock Registry and Mock CDS (separate Helm charts)
- Shows deployment status

**Note**: Mock BAP-Kafka and Mock BPP-Kafka are not automatically deployed as they don't have Helm charts. See [Deploying Mock Kafka Services](#deploying-mock-kafka-services) section below.

**Option 2: Manual Deployment**

**IMPORTANT**: You must run these commands from the `helm-sandbox-kafka` directory.

```bash
# Navigate to helm-sandbox-kafka directory (from project root)
cd helm-sandbox-kafka

# Verify you're in the right directory (should see values-sandbox.yaml)
pwd
# Should output: .../ubc-ev-sandbox/helm-sandbox-kafka
ls values-sandbox.yaml

# Deploy all services (BAP, BPP, and mock services)
# Note: BAP release includes Kafka, Kafka UI, and Redis
# Using fullnameOverride=onix ensures Kafka service is named "onix-kafka" (shared by both BAP and BPP)
helm upgrade --install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix \
  --namespace ev-charging-sandbox \
  --create-namespace && \
# BPP release uses Kafka and Redis from BAP release
# Using the same fullnameOverride=onix ensures consistent service naming
helm upgrade --install onix-bpp ../helm-kafka \
  -f ../helm-kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix \
  --namespace ev-charging-sandbox && \
# Deploy Mock Registry (separate Helm chart)
helm upgrade --install mock-registry ../mock/mock-registry \
  --set fullnameOverride=mock-registry \
  --namespace ev-charging-sandbox && \
# Deploy Mock CDS (separate Helm chart)
helm upgrade --install mock-cds ../mock/mock-cds \
  --set fullnameOverride=mock-cds \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox

# Watch pod status (optional)
watch -n 2 'kubectl get pods -n ev-charging-sandbox'
```

**Alternative: Using Absolute Paths**

If you prefer to use absolute paths or run from a different directory:

```bash
# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Deploy all services using absolute paths
helm upgrade --install ev-charging-kafka-bap ${PROJECT_ROOT}/helm-kafka \
  -f ${PROJECT_ROOT}/helm-kafka/values-bap.yaml \
  -f ${PROJECT_ROOT}/helm-sandbox-kafka/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-kafka-bpp ${PROJECT_ROOT}/helm-kafka \
  -f ${PROJECT_ROOT}/helm-kafka/values-bpp.yaml \
  -f ${PROJECT_ROOT}/helm-sandbox-kafka/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox
```

**Troubleshooting Path Issues**

If you get "path not found" errors:

1. **Verify you're in the correct directory**:
   ```bash
   pwd
   # Should end with: .../ubc-ev-sandbox/helm-sandbox-kafka
   ```

2. **Check the paths exist**:
   ```bash
   ls -d ../helm-kafka
   ```

3. **Use absolute paths** (see Alternative method above)

4. **Or navigate from project root**:
   ```bash
   # From project root
   cd helm-sandbox-kafka
   # Then run the helm commands
   ```

### Deploy BAP Component

```bash
# Navigate to this directory
cd helm-sandbox-kafka

# Deploy BAP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install onix-bap-1 ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap-1 \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install onix-bap-2 ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap-2 \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods -l app.kubernetes.io/component=bap
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bap  # If using namespace
kubectl get svc -n ev-charging-sandbox -l app.kubernetes.io/component=bap
```

### Deploy BPP Component

```bash
# Deploy BPP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install onix-bpp ../helm-kafka \
  -f ../helm-kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bpp ../helm-kafka \
  -f ../helm-kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install onix-bpp ../helm-kafka \
  -f ../helm-kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bpp ../helm-kafka \
  -f ../helm-kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Check deployment status
kubectl get pods -l app.kubernetes.io/component=bpp
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bpp  # If using namespace
kubectl get svc -n ev-charging-sandbox -l app.kubernetes.io/component=bpp
```

### Using Namespaces

You can deploy to a specific namespace using the `--namespace` flag. The `--create-namespace` flag will create the namespace if it doesn't exist:

```bash
# Create namespace first (optional)
kubectl create namespace ev-charging-sandbox

# Deploy with namespace (idempotent - installs or upgrades)
helm upgrade --install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# All kubectl commands should include -n flag when using namespace
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox
kubectl logs -n ev-charging-sandbox <pod-name>
```

### Deploy All Services Together (Alternative Section)

This section provides an alternative way to deploy all services. See the [Deploy Complete Sandbox Environment](#deploy-complete-sandbox-environment-all-services) section above for the recommended approach.

```bash
# Navigate to helm-sandbox-kafka directory
cd helm-sandbox-kafka

# Deploy BAP (idempotent - installs or upgrades)
helm upgrade --install onix-bap ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP (idempotent - installs or upgrades)
helm upgrade --install onix-bpp ../helm-kafka \
  -f ../helm-kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox

# Deploy Mock Registry (separate Helm chart)
helm upgrade --install mock-registry ../mock/mock-registry \
  --set fullnameOverride=mock-registry \
  --namespace ev-charging-sandbox

# Deploy Mock CDS (separate Helm chart)
helm upgrade --install mock-cds ../mock/mock-cds \
  --set fullnameOverride=mock-cds \
  --namespace ev-charging-sandbox

# Note: Mock BAP-Kafka and Mock BPP-Kafka do not have Helm charts.
# They are configured via values-sandbox.yaml but need to be deployed manually
# or via docker-compose. See mock/mock-bap-kafka/ and mock/mock-bpp-kafka/ directories.
```

### Deploying Mock Kafka Services

Mock BAP-Kafka and Mock BPP-Kafka services do not have Helm charts and need to be deployed manually. You have two options:

**Option 1: Manual Kubernetes Deployment**

Create Kubernetes deployments and services manually using the configuration from `values-sandbox.yaml`:

```bash
# Example: Deploy mock-bap-kafka manually
kubectl create deployment ev-charging-mock-bap-kafka \
  --image=manendrapalsingh/mock-bap-kafka:latest \
  --namespace ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Create service (if needed for health checks)
kubectl create service clusterip ev-charging-mock-bap-kafka \
  --tcp=9003:9003 \
  --namespace ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Option 2: Use Docker Compose (for local development)**

If running locally, you can use docker-compose from the `sandbox-kafka/` directory:

```bash
cd ../sandbox-kafka
docker-compose up -d mock-bap-kafka mock-bpp-kafka
```

**Note**: The mock Kafka services are configured in `values-sandbox.yaml` but are not automatically deployed. They need to be deployed separately as shown above.

### Installing Multiple Instances

If you need multiple instances of the same component in the same namespace, use different release names:

```bash
# Install first BAP instance
helm install onix-bap-1 ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap-1 \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install second BAP instance with different name
helm install onix-bap-2 ../helm-kafka \
  -f ../helm-kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap-2 \
  --namespace ev-charging-sandbox

# Each instance will have different service names and can run on different ports
```

## Services

### Core Services

1. **kafka** (Port: 9092)
   - Kafka message broker (KRaft mode - no Zookeeper needed)
   - Used for message routing between adapters and mock services
   - Controller port: 9093 (internal)

2. **redis-bap** (Port: 6379)
   - Redis cache for the BAP adapter
   - Used for storing transaction state, caching registry lookups, and session management

3. **redis-bpp** (Port: 6380)
   - Redis cache for the BPP adapter
   - Used for storing transaction state, caching registry lookups, and session management

4. **onix-bap-service** (Port: 8001)
   - ONIX protocol adapter for BAP (Buyer App Provider) with Kafka integration
   - **HTTP Handler** (`bapTxnReceiver`): Receives HTTP requests from BPP adapter at `/bap/receiver/` and publishes to Kafka
   - **Queue Consumer** (`bapTxnCaller`): Consumes messages from Kafka topics:
     - `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
   - Handles protocol compliance, signing, validation, and routing for BAP transactions

5. **onix-bpp-service** (Port: 8002)
   - ONIX protocol adapter for BPP (Buyer Platform Provider) with Kafka integration
   - **HTTP Handler** (`bppTxnReceiver`): Receives HTTP requests from BAP adapter at `/bpp/receiver/` and publishes to Kafka
   - **Queue Consumer** (`bppTxnCaller`): Consumes callbacks from Kafka topics:
     - `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`
   - Routes callbacks to BAP adapter or CDS via HTTP
   - Handles protocol compliance, signing, validation, and routing for BPP transactions

### Mock Services

6. **mock-registry** (Port: 3030)
   - Mock implementation of the network registry service
   - Maintains a registry of all BAPs, BPPs, and CDS services on the network
   - Provides subscriber lookup and key management functionality

7. **mock-cds** (Port: 8082)
   - Mock Catalog Discovery Service (CDS)
   - Aggregates discover requests from BAPs and broadcasts to registered BPPs
   - Collects and aggregates responses from multiple BPPs
   - Handles signature verification and signing

8. **mock-bap-kafka** (Internal Port: 9003)
   - Mock BAP backend service with Kafka integration
   - Simulates a Buyer App Provider application
   - Consumes messages from Kafka topics (routing keys: `bap.on_discover`, `bap.on_select`, etc.)
   - Publishes requests to Kafka for ONIX adapter processing
   - **Note**: Runs in queue-only mode - no external HTTP ports exposed

9. **mock-bpp-kafka** (Internal Port: 9004)
   - Mock BPP backend service with Kafka integration
   - Simulates a Buyer Platform Provider application
   - Consumes messages from Kafka topics (routing keys: `bpp.discover`, `bpp.select`, etc.)
   - Publishes responses to Kafka for ONIX adapter processing
   - **Note**: Runs in queue-only mode - no external HTTP ports exposed

10. **kafka-ui** (Port: 8080)
    - Web UI for managing and monitoring Kafka
    - Provides topic management, message browsing, and cluster monitoring

## Configuration Files

### `values-sandbox.yaml`

This file contains sandbox-specific overrides for the Helm chart. It includes:

- Mock services configuration (registry, CDS, BAP-Kafka, BPP-Kafka)
- Kafka UI configuration
- Service configurations with Kubernetes service names

### Config Files

- **`mock-registry_config.yml`**: Registry service configuration
- **`mock-cds_config.yml`**: CDS service configuration
- **`mock-bap-kafka_config.yml`**: Mock BAP Kafka service configuration
- **`mock-bpp-kafka_config.yml`**: Mock BPP Kafka service configuration

## Service Endpoints

Once all services are deployed, you can access them via Kubernetes services:

| Service | Service Name | Port | Description |
|---------|--------------|------|-------------|
| **Kafka** | `onix-kafka` | 9092 | Kafka broker (from BAP release, shared with BPP) |
| **Kafka UI** | `onix-kafka-ui` | 8080 | Kafka Management UI (from BAP release, shared with BPP) |
| **Mock Registry** | `mock-registry` | 3030 | Registry service |
| **Mock CDS** | `mock-cds` | 8082 | Catalog Discovery Service |
| **ONIX BAP Plugin** | `onix-bap-service` | 8001 | HTTP endpoint for bapTxnReceiver |
| **ONIX BPP Plugin** | `onix-bpp-service` | 8002 | HTTP endpoint for bppTxnReceiver |
| **Redis BAP** | `onix-bap-redis-bap` | 6379 | Redis cache for BAP adapter |
| **Redis BPP** | `onix-bpp-redis-bpp` | 6379 | Redis cache for BPP adapter |
| **Mock BAP Kafka** | Queue-based | - | Consumes from Kafka topics |
| **Mock BPP Kafka** | Queue-based | - | Consumes from Kafka topics |

## Accessing Services

### Port Forwarding

**Option 1: Using the Port Forward Script (Recommended)**

The easiest way to set up port forwarding is using the provided script:

```bash
# Run from helm-sandbox-kafka directory
cd helm-sandbox-kafka
./port-forward.sh
```

The script automatically sets up port forwarding for:
- Kafka UI (port 8080)
- BAP adapter (port 8001)
- BPP adapter (port 8002)
- Mock Registry (port 3030) - if deployed
- Mock CDS (port 8082) - if deployed

**Option 2: Manual Port Forwarding**

To access services from your local machine manually:

```bash
# Port forward Kafka UI
kubectl port-forward -n ev-charging-sandbox svc/onix-kafka-ui 8080:8080

# Port forward Mock Registry
kubectl port-forward -n ev-charging-sandbox svc/mock-registry 3030:3030

# Port forward Mock CDS
kubectl port-forward -n ev-charging-sandbox svc/mock-cds 8082:8082

# Port forward ONIX BAP Plugin
kubectl port-forward -n ev-charging-sandbox svc/onix-bap-service 8001:8001

# Port forward ONIX BPP Plugin
kubectl port-forward -n ev-charging-sandbox svc/onix-bpp-service 8002:8002
```

**Note**: Run port forwarding commands in separate terminal windows/tabs to keep them running, or use the port-forward script which manages all forwards.

### Using Ingress (if configured)

If you have an Ingress controller configured, you can access services via Ingress routes.

## Message Flow

### Service Discovery Flow (Phase 1)

1. **BAP Application** → Publishes `discover` request to Kafka topic `bap.discover`
2. **ONIX BAP Plugin** → Consumes message, routes to **Mock CDS** via HTTP
3. **Mock CDS** → Broadcasts discover to all registered BPPs
4. **ONIX BPP Plugin** → Receives discover from CDS, publishes to Kafka topic `bpp.discover` (to BPP Backend)
5. **Mock BPP Kafka** → Consumes `bpp.discover`, processes, publishes `on_discover` response
6. **ONIX BPP Plugin** → Routes `on_discover` response to **Mock CDS** via HTTP
7. **Mock CDS** → Aggregates responses, sends to **ONIX BAP Plugin**
8. **ONIX BAP Plugin** → Publishes aggregated response to Kafka topic `bap.on_discover`
9. **Mock BAP Kafka** → Consumes `bap.on_discover` callback

### Transaction Flow (Phase 2+)

1. **BAP Application** → Publishes `select/init/confirm` request to Kafka topics `bap.select/bap.init/bap.confirm`
2. **ONIX BAP Plugin** → Consumes message, routes directly to **ONIX BPP Plugin** (bypasses CDS)
3. **ONIX BPP Plugin** → Publishes to Kafka topics `bpp.select/bpp.init/bpp.confirm` (to BPP Backend)
4. **Mock BPP Kafka** → Consumes request, processes, publishes response
5. **ONIX BPP Plugin** → Routes callback to **ONIX BAP Plugin**
6. **ONIX BAP Plugin** → Publishes callback to Kafka topics `bap.on_select/bap.on_init/bap.on_confirm`
7. **Mock BAP Kafka** → Consumes callback

## Kafka Topic Structure

### BAP Topics
- `bap.discover`
- `bap.select`
- `bap.init`
- `bap.confirm`
- `bap.status`
- `bap.track`
- `bap.cancel`
- `bap.update`
- `bap.rating`
- `bap.support`
- `bap.on_discover`
- `bap.on_select`
- `bap.on_init`
- `bap.on_confirm`
- `bap.on_status`
- `bap.on_track`
- `bap.on_cancel`
- `bap.on_update`
- `bap.on_rating`
- `bap.on_support`

### BPP Topics
- `bpp.discover`
- `bpp.select`
- `bpp.init`
- `bpp.confirm`
- `bpp.status`
- `bpp.track`
- `bpp.cancel`
- `bpp.update`
- `bpp.rating`
- `bpp.support`
- `bpp.on_discover`
- `bpp.on_select`
- `bpp.on_init`
- `bpp.on_confirm`
- `bpp.on_status`
- `bpp.on_track`
- `bpp.on_cancel`
- `bpp.on_update`
- `bpp.on_rating`
- `bpp.on_support`

## Kafka UI

The Kafka UI provides a web-based interface for monitoring and managing Kafka.

### Accessing Kafka UI

1. **Port forward the service**:
   ```bash
   kubectl port-forward -n ev-charging-sandbox svc/onix-kafka-ui 8080:8080
   ```
   
   Or use the port-forward script:
   ```bash
   ./port-forward.sh
   ```

2. **Open the Management UI**:
   - URL: `http://localhost:8080`
   - The UI will automatically connect to the Kafka cluster

### Features

- View topics and partitions
- Browse messages
- Monitor consumer groups
- View cluster metrics

## Publishing Test Messages

The `message/` directory contains example JSON messages and shell scripts for publishing test messages to Kafka topics.

### Using the Test Scripts

```bash
# Navigate to message directory
cd message/bap/test

# Publish a discover message
./publish-discover-by-station.sh

# Publish all messages
./publish-all.sh

# Publish specific action type
./publish-all.sh discover
./publish-all.sh select
```

The scripts automatically detect the environment and use the appropriate method:
- **Kubernetes/Helm**: Uses `kubectl exec` to access the Kafka pod
- **Docker Compose**: Uses `docker exec` if Kafka container is running
- **Local**: Uses Kafka CLI tools if installed

For detailed information about message structure, topics, and troubleshooting, see the [Message Directory README](message/README.md).

## Troubleshooting

### Check Pod Status

```bash
# Check all pods
kubectl get pods -n ev-charging-sandbox

# Check specific component
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bap
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bpp
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=kafka

# Check pod logs
kubectl logs -n ev-charging-sandbox <pod-name>
kubectl logs -f -n ev-charging-sandbox <pod-name>  # Follow logs
kubectl logs -n ev-charging-sandbox -l app.kubernetes.io/component=bap  # Logs for all BAP pods
kubectl logs -n ev-charging-sandbox -l app.kubernetes.io/component=bpp  # Logs for all BPP pods
```

### Check Kafka Topics

```bash
# Port forward Kafka UI and check topics via web UI
kubectl port-forward -n ev-charging-sandbox svc/onix-kafka-ui 8080:8080
# Then open http://localhost:8080 in your browser

# Or use kubectl exec to access Kafka pod
KAFKA_POD=$(kubectl get pod -n ev-charging-sandbox -l component=kafka -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n ev-charging-sandbox $KAFKA_POD -- kafka-topics --bootstrap-server localhost:9092 --list
```

### Check Services

```bash
# List all services
kubectl get svc -n ev-charging-sandbox

# Check service endpoints
kubectl get endpoints -n ev-charging-sandbox

# Check specific component services
kubectl get svc -n ev-charging-sandbox -l app.kubernetes.io/component=bap
kubectl get svc -n ev-charging-sandbox -l app.kubernetes.io/component=bpp
```

### Common Issues

1. **Kafka pod not starting**: Check resource limits and node capacity (Kafka requires significant memory)
2. **Topics not created**: Verify Kafka admin configuration in adapter config
3. **Messages not consumed**: Check consumer group configuration and pod logs
4. **Network issues**: Verify service names are correct in configuration
5. **Redis authentication errors (NOAUTH)**: 
   - Ensure `config.keys.redisPassword` is set in values-bap.yaml and values-bpp.yaml
   - The password must match `redis.password` in values.yaml
   - Default password is `your-redis-password` for sandbox
   - Check adapter logs: `kubectl logs -n ev-charging-sandbox -l component=bap` or `-l component=bpp`
   - Verify Redis is running: `kubectl get pods -n ev-charging-sandbox -l component=redis`

## Uninstalling

### Quick Uninstall (All Services)

To remove the complete Kafka sandbox environment in one command:

```bash
# Uninstall all Helm releases at once
helm uninstall onix-bap onix-bpp mock-registry mock-cds \
  --namespace ev-charging-sandbox

# Verify all releases are uninstalled
helm list -n ev-charging-sandbox

# Remove namespace (optional - removes all resources in namespace)
kubectl delete namespace ev-charging-sandbox
```

### Step-by-Step Uninstall

For more control, uninstall services step by step:

```bash
# 1. Uninstall ONIX adapters
helm uninstall onix-bap --namespace ev-charging-sandbox
helm uninstall onix-bpp --namespace ev-charging-sandbox

# 2. Uninstall mock services
helm uninstall mock-registry --namespace ev-charging-sandbox
helm uninstall mock-cds --namespace ev-charging-sandbox

# 2. Clean up remaining resources (if not deleting namespace)
kubectl delete configmap -n ev-charging-sandbox -l app.kubernetes.io/name=onix-kafka
kubectl delete pvc -n ev-charging-sandbox -l app.kubernetes.io/name=onix-kafka
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-kafka

# 3. Remove namespace (optional - removes everything in namespace)
kubectl delete namespace ev-charging-sandbox
```

### Verification Commands

After uninstalling, verify all resources are removed:

```bash
# Verify all Helm releases are uninstalled
helm list -n ev-charging-sandbox

# Verify all pods are removed
kubectl get pods -n ev-charging-sandbox

# Verify all services are removed
kubectl get svc -n ev-charging-sandbox

# Verify all ConfigMaps are removed
kubectl get configmap -n ev-charging-sandbox
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Main Helm Chart README](../helm-kafka/README.md) - Detailed Helm chart documentation
- [Message Directory README](message/README.md) - Kafka message structure and testing guide
- [Docker Sandbox README](../sandbox-kafka/README.md) - Docker Compose equivalent setup

## Notes

- Kafka runs in KRaft mode (no Zookeeper required)
- Service names in Kubernetes use DNS resolution within the cluster
- All services communicate using Kubernetes service names (e.g., `onix-bap-kafka:9092`)
- Configuration is managed through Helm values files and ConfigMaps
- Mock Kafka services run in queue-only mode (no external HTTP ports)
- Production deployments should use proper secrets management for keys and credentials
- Kafka requires persistent storage for production deployments
- **Redis Password**: The Redis password must be set in both `redis.password` and `config.keys.redisPassword` in the values files. The adapter uses `config.keys.redisPassword` to set the `REDIS_PASSWORD` environment variable.
- **Service Deployment**: BAP release deploys Kafka, Kafka UI, Redis, and mock services. BPP release uses the shared Kafka and Redis from BAP release.

