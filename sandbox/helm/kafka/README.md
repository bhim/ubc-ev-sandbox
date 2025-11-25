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
# Run from sandbox/helm/kafka directory
cd sandbox/helm/kafka
./deploy-all.sh
```

The script automatically:
- Verifies all paths exist
- Creates the namespace if needed
- Deploys all services (BAP, BPP, Kafka, and mock services)
- Populates schemas
- Shows deployment status

**Option 2: Manual Deployment**

**IMPORTANT**: You must run these commands from the `sandbox/helm/kafka` directory.

```bash
# Navigate to sandbox directory (from project root)
cd sandbox/helm/kafka

# Verify you're in the right directory (should see values-sandbox.yaml)
pwd
# Should output: .../ev_charging_sandbox/sandbox/helm/kafka
ls values-sandbox.yaml

# Deploy all services (BAP, BPP, and mock services)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-registry ../../mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-cds ../../mock-cds \
  --namespace ev-charging-sandbox

# Populate schemas (required for validation)
./populate-schemas.sh

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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"

# Deploy all services using absolute paths
helm upgrade --install ev-charging-kafka-bap ${PROJECT_ROOT}/helm/kafka \
  -f ${PROJECT_ROOT}/helm/kafka/values-bap.yaml \
  -f ${PROJECT_ROOT}/sandbox/helm/kafka/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-kafka-bpp ${PROJECT_ROOT}/helm/kafka \
  -f ${PROJECT_ROOT}/helm/kafka/values-bpp.yaml \
  -f ${PROJECT_ROOT}/sandbox/helm/kafka/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-registry ${PROJECT_ROOT}/sandbox/mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-cds ${PROJECT_ROOT}/sandbox/mock-cds \
  --namespace ev-charging-sandbox
```

**Troubleshooting Path Issues**

If you get "path not found" errors:

1. **Verify you're in the correct directory**:
   ```bash
   pwd
   # Should end with: .../ev_charging_sandbox/sandbox/helm/kafka
   ```

2. **Check the paths exist**:
   ```bash
   ls -d ../../../helm/kafka
   ls -d ../../mock-registry
   ```

3. **Use absolute paths** (see Alternative method above)

4. **Or navigate from project root**:
   ```bash
   # From project root
   cd sandbox/helm/kafka
   # Then run the helm commands
   ```

### Deploy BAP Component

```bash
# Navigate to this directory
cd sandbox/helm/kafka

# Deploy BAP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-kafka-bap-1 ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-kafka-bap-2 ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods -l app.kubernetes.io/component=bap
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bap  # If using namespace
kubectl get svc -l app.kubernetes.io/component=bap
```

### Deploy BPP Component

```bash
# Deploy BPP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Check deployment status
kubectl get pods -l app.kubernetes.io/component=bpp
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bpp  # If using namespace
kubectl get svc -l app.kubernetes.io/component=bpp
```

### Using Namespaces

You can deploy to a specific namespace using the `--namespace` flag. The `--create-namespace` flag will create the namespace if it doesn't exist:

```bash
# Create namespace first (optional)
kubectl create namespace ev-charging-sandbox

# Deploy with namespace (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
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
# Navigate to sandbox/helm/kafka directory
cd sandbox/helm/kafka

# Deploy BAP (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy Mock Registry
helm upgrade --install mock-registry ../../mock-registry \
  --namespace ev-charging-sandbox

# Deploy Mock CDS
helm upgrade --install mock-cds ../../mock-cds \
  --namespace ev-charging-sandbox

# Populate schemas
./populate-schemas.sh

# Note: Mock BAP-Kafka and Mock BPP-Kafka services are configured via values-sandbox.yaml
# and may be deployed as part of the Kafka Helm chart if the chart supports it.
```

### Installing Multiple Instances

If you need multiple instances of the same component in the same namespace, use different release names:

```bash
# Install first BAP instance
helm install ev-charging-kafka-bap-1 ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install second BAP instance with different name
helm install ev-charging-kafka-bap-2 ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
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

4. **onix-bap-plugin-kafka** (Port: 8001)
   - ONIX protocol adapter for BAP (Buyer App Provider) with Kafka integration
   - **HTTP Handler** (`bapTxnReceiver`): Receives HTTP requests from BPP adapter at `/bap/receiver/` and publishes to Kafka
   - **Queue Consumer** (`bapTxnCaller`): Consumes messages from Kafka topics:
     - `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
   - Handles protocol compliance, signing, validation, and routing for BAP transactions

5. **onix-bpp-plugin-kafka** (Port: 8002)
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
| **Kafka** | `kafka` | 9092 | Kafka broker |
| **Kafka UI** | `kafka-ui` | 8080 | Kafka Management UI |
| **Mock Registry** | `mock-registry` | 3030 | Registry service |
| **Mock CDS** | `mock-cds` | 8082 | Catalog Discovery Service |
| **ONIX BAP Plugin** | `onix-bap-plugin-kafka` | 8001 | HTTP endpoint for bapTxnReceiver |
| **ONIX BPP Plugin** | `onix-bpp-plugin-kafka` | 8002 | HTTP endpoint for bppTxnReceiver |
| **Mock BAP Kafka** | Queue-based | - | Consumes from Kafka topics |
| **Mock BPP Kafka** | Queue-based | - | Consumes from Kafka topics |

## Accessing Services

### Port Forwarding

To access services from your local machine:

```bash
# Port forward Kafka UI
kubectl port-forward svc/kafka-ui 8080:8080

# Port forward Mock Registry
kubectl port-forward svc/mock-registry 3030:3030

# Port forward Mock CDS
kubectl port-forward svc/mock-cds 8082:8082

# Port forward ONIX BAP Plugin
kubectl port-forward svc/onix-bap-plugin-kafka 8001:8001

# Port forward ONIX BPP Plugin
kubectl port-forward svc/onix-bpp-plugin-kafka 8002:8002
```

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
   kubectl port-forward svc/kafka-ui 8080:8080
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
./publish-discover.sh

# Publish all messages
./publish-all.sh
```

**Note**: You'll need to update the scripts to use Kubernetes service names and port-forwarding if accessing from outside the cluster.

## Schema Configuration

The ONIX adapters require JSON schemas for validation. Schemas are automatically populated from the `schemas/beckn.one_deg_ev-charging/v2.0.0/` directory into Kubernetes ConfigMaps.

### Populating Schemas

Schemas need to be populated into ConfigMaps before pods can use them:

**Option 1: Using the helper script (Recommended)**

```bash
# From sandbox/helm/kafka directory
./populate-schemas.sh

# Or specify custom release names
RELEASE_BAP=my-kafka-bap RELEASE_BPP=my-kafka-bpp ./populate-schemas.sh

# Or specify custom namespace
NAMESPACE=my-namespace ./populate-schemas.sh
```

**Option 2: Manual ConfigMap creation**

```bash
# Create schemas ConfigMap for BAP
kubectl create configmap ev-charging-kafka-bap-onix-kafka-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Create schemas ConfigMap for BPP
kubectl create configmap ev-charging-kafka-bpp-onix-kafka-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new schemas
kubectl delete pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-kafka-bap
kubectl delete pod -n ev-charging-sandbox -l component=bpp,app.kubernetes.io/instance=ev-charging-kafka-bpp
```

### Verifying Schemas

After deployment, verify schemas are correctly mounted:

```bash
# Check if schemas are present in BAP pod
kubectl exec -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-kafka-bap -o jsonpath='{.items[0].metadata.name}') \
  -- ls -la /app/schemas/beckn.one_deg_ev-charging/v2.0.0/
```

### Updating Schemas

When schema files are updated:

1. Update the ConfigMap:
   ```bash
   ./populate-schemas.sh
   ```

2. Restart the pods:
   ```bash
   kubectl delete pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-kafka-bap
   kubectl delete pod -n ev-charging-sandbox -l component=bpp,app.kubernetes.io/instance=ev-charging-kafka-bpp
   ```

### Schema Validation Errors

If you encounter errors like `schema validation failed: schema not found for domain: beckn.one_deg_ev-charging`:

1. **Verify ConfigMap exists:**
   ```bash
   kubectl get configmap -n ev-charging-sandbox | grep schemas
   ```

2. **Check ConfigMap contents:**
   ```bash
   kubectl get configmap ev-charging-kafka-bap-onix-kafka-schemas \
     -n ev-charging-sandbox -o jsonpath='{.data}' | jq 'keys'
   ```

3. **Repopulate schemas:**
   ```bash
   ./populate-schemas.sh
   kubectl delete pod -n ev-charging-sandbox -l component=bap
   kubectl delete pod -n ev-charging-sandbox -l component=bpp
   ```

4. **Check pod logs for schema loading errors:**
   ```bash
   kubectl logs -n ev-charging-sandbox \
     $(kubectl get pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-kafka-bap -o jsonpath='{.items[0].metadata.name}') \
     | grep -i schema
   ```

For more details, see [Schema Setup Guide](../SCHEMA_SETUP.md).

## Troubleshooting

### Check Pod Status

```bash
# Check all pods
kubectl get pods

# Check specific component
kubectl get pods -l app.kubernetes.io/component=bap
kubectl get pods -l app.kubernetes.io/component=bpp

# Check pod logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
```

### Check Kafka Topics

```bash
# Port forward Kafka UI and check topics via web UI
kubectl port-forward svc/kafka-ui 8080:8080

# Or use kubectl exec to access Kafka pod
kubectl exec -it <kafka-pod-name> -- kafka-topics --bootstrap-server localhost:9092 --list
```

### Check Services

```bash
# List all services
kubectl get svc

# Check service endpoints
kubectl get endpoints
```

### Common Issues

1. **Kafka pod not starting**: Check resource limits and node capacity (Kafka requires significant memory)
2. **Topics not created**: Verify Kafka admin configuration in adapter config
3. **Messages not consumed**: Check consumer group configuration and pod logs
4. **Network issues**: Verify service names are correct in configuration

## Uninstalling

```bash
# Uninstall BAP (default namespace)
helm uninstall ev-charging-kafka-bap

# Uninstall BPP (default namespace)
helm uninstall ev-charging-kafka-bpp

# Uninstall from specific namespace
helm uninstall ev-charging-kafka-bap --namespace ev-charging-sandbox
helm uninstall ev-charging-kafka-bpp --namespace ev-charging-sandbox

# Remove all resources (if needed)
kubectl delete all -l app.kubernetes.io/name=onix-kafka
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-kafka  # If using namespace
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Main Helm Chart README](../../../../helm/kafka/README.md) - Detailed Helm chart documentation
- [Docker Sandbox README](../../../docker/kafka/README.md) - Docker Compose equivalent setup

## Notes

- Kafka runs in KRaft mode (no Zookeeper required)
- Service names in Kubernetes use DNS resolution within the cluster
- All services communicate using Kubernetes service names (e.g., `kafka:9092`)
- Configuration is managed through Helm values files and ConfigMaps
- Mock Kafka services run in queue-only mode (no external HTTP ports)
- Production deployments should use proper secrets management for keys and credentials
- Kafka requires persistent storage for production deployments

