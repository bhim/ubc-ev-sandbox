# EV Charging Sandbox - RabbitMQ Helm Setup

This directory contains Helm values files for deploying a complete EV Charging sandbox environment using Kubernetes/Helm with RabbitMQ message broker integration. The setup includes ONIX adapters (BAP and BPP), mock services (CDS, Registry, BAP-RabbitMQ, BPP-RabbitMQ), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol with RabbitMQ for asynchronous message processing. The architecture includes:

- **ONIX RabbitMQ Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider) that consume and publish messages via RabbitMQ
- **Mock Services**: Simulated services for testing without real implementations
- **RabbitMQ Message Broker**: Central message broker for asynchronous communication with Management UI
- **Supporting Services**: Redis for caching and state management

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to Docker images (pulled automatically from Docker Hub)
- Sufficient cluster resources for RabbitMQ (recommended: 512MB+ memory per node)

## Quick Start

### Deploy Complete Sandbox Environment (All Services)

Deploy the complete RabbitMQ sandbox environment with all services (BAP, BPP, RabbitMQ, and all mock services) in one go:

**🚀 Quick Deploy - All Services**

**Option 1: Manual Deployment**

**IMPORTANT**: You must run these commands from the `sandbox/helm/rabbitmq` directory.

```bash
# Navigate to sandbox directory (from project root)
cd sandbox/helm/rabbitmq

# Verify you're in the right directory (should see values-sandbox.yaml)
pwd
# Should output: .../ev_charging_sandbox/sandbox/helm/rabbitmq
ls values-sandbox.yaml

# Deploy all services (BAP, BPP, and mock services)
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
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

**Option 2: Using Absolute Paths**

If you prefer to use absolute paths or run from a different directory:

```bash
# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"

# Deploy all services using absolute paths
helm upgrade --install ev-charging-rabbitmq-bap ${PROJECT_ROOT}/helm/rabbitmq \
  -f ${PROJECT_ROOT}/helm/rabbitmq/values-bap.yaml \
  -f ${PROJECT_ROOT}/sandbox/helm/rabbitmq/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-rabbitmq-bpp ${PROJECT_ROOT}/helm/rabbitmq \
  -f ${PROJECT_ROOT}/helm/rabbitmq/values-bpp.yaml \
  -f ${PROJECT_ROOT}/sandbox/helm/rabbitmq/values-sandbox.yaml \
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
   # Should end with: .../ev_charging_sandbox/sandbox/helm/rabbitmq
   ```

2. **Check the paths exist**:
   ```bash
   ls -d ../../../helm/rabbitmq
   ls -d ../../mock-registry
   ```

3. **Use absolute paths** (see Option 2 above)

4. **Or navigate from project root**:
   ```bash
   # From project root
   cd sandbox/helm/rabbitmq
   # Then run the helm commands
   ```

### Deploy BAP Component

```bash
# Navigate to this directory
cd sandbox/helm/rabbitmq

# Deploy BAP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-rabbitmq-bap-1 ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-rabbitmq-bap-2 ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
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
helm install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
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
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
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
# Navigate to sandbox/helm/rabbitmq directory
cd sandbox/helm/rabbitmq

# Deploy BAP (idempotent - installs or upgrades)
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP (idempotent - installs or upgrades)
helm upgrade --install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
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

# Note: Mock BAP-RabbitMQ and Mock BPP-RabbitMQ services are configured via values-sandbox.yaml
# and may be deployed as part of the RabbitMQ Helm chart if the chart supports it.
```

### Installing Multiple Instances

If you need multiple instances of the same component in the same namespace, use different release names:

```bash
# Install first BAP instance
helm install ev-charging-rabbitmq-bap-1 ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install second BAP instance with different name
helm install ev-charging-rabbitmq-bap-2 ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Each instance will have different service names and can run on different ports
```

## Services

### Core Services

1. **rabbitmq** (Ports: 5672 AMQP, 15672 Management UI)
   - RabbitMQ message broker for asynchronous communication
   - Used for message routing between adapters and mock services
   - Management UI available at port 15672 (admin/admin)

2. **redis-bap** (Port: 6379)
   - Redis cache for the BAP adapter
   - Used for storing transaction state, caching registry lookups, and session management

3. **redis-bpp** (Port: 6379)
   - Redis cache for the BPP adapter
   - Used for storing transaction state, caching registry lookups, and session management

4. **onix-bap-plugin-rabbitmq** (Port: 8001)
   - ONIX protocol adapter for BAP (Buyer App Provider) with RabbitMQ integration
   - **HTTP Handler** (`bapTxnReceiver`): Receives HTTP requests from BPP adapter at `/bap/receiver/` and publishes to RabbitMQ
   - **Queue Consumer** (`bapTxnCaller`): Consumes messages from `bap_caller_queue` with routing keys:
     - `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
   - Handles protocol compliance, signing, validation, and routing for BAP transactions

5. **onix-bpp-plugin-rabbitmq** (Port: 8002)
   - ONIX protocol adapter for BPP (Buyer Platform Provider) with RabbitMQ integration
   - **HTTP Handler** (`bppTxnReceiver`): Receives HTTP requests from BAP adapter at `/bpp/receiver/` and publishes to RabbitMQ
   - **Queue Consumer** (`bppTxnCaller`): Consumes callbacks from `bpp_caller_queue` with routing keys:
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

8. **mock-bap-rabbitmq** (Internal Port: 9003)
   - Mock BAP backend service with RabbitMQ integration
   - Simulates a Buyer App Provider application
   - Consumes messages from RabbitMQ queues (routing keys: `bap.on_discover`, `bap.on_select`, etc.)
   - Publishes requests to RabbitMQ for ONIX adapter processing
   - **Note**: Runs in queue-only mode - no external HTTP ports exposed

9. **mock-bpp-rabbitmq** (Internal Port: 9004)
   - Mock BPP backend service with RabbitMQ integration
   - Simulates a Buyer Platform Provider application
   - Consumes messages from RabbitMQ queues (routing keys: `bpp.discover`, `bpp.select`, etc.)
   - Publishes responses to RabbitMQ for ONIX adapter processing
   - **Note**: Runs in queue-only mode - no external HTTP ports exposed

## Configuration Files

### `values-sandbox.yaml`

This file contains sandbox-specific overrides for the Helm chart. It includes:

- Mock services configuration (registry, CDS, BAP-RabbitMQ, BPP-RabbitMQ)
- RabbitMQ Management UI configuration
- Service configurations with Kubernetes service names

### Config Files

- **`mock-registry_config.yml`**: Registry service configuration
- **`mock-cds_config.yml`**: CDS service configuration
- **`mock-bap-rabbitMq_config.yml`**: Mock BAP RabbitMQ service configuration
- **`mock-bpp-rabbitMq_config.yml`**: Mock BPP RabbitMQ service configuration

## Service Endpoints

Once all services are deployed, you can access them via Kubernetes services:

| Service | Service Name | Port | Description |
|---------|--------------|------|-------------|
| **RabbitMQ** | `rabbitmq` | 5672 | RabbitMQ AMQP broker |
| **RabbitMQ Management** | `rabbitmq` | 15672 | RabbitMQ Management UI |
| **Mock Registry** | `mock-registry` | 3030 | Registry service |
| **Mock CDS** | `mock-cds` | 8082 | Catalog Discovery Service |
| **ONIX BAP Plugin** | `onix-bap-plugin-rabbitmq` | 8001 | HTTP endpoint for bapTxnReceiver |
| **ONIX BPP Plugin** | `onix-bpp-plugin-rabbitmq` | 8002 | HTTP endpoint for bppTxnReceiver |
| **Mock BAP RabbitMQ** | Queue-based | - | Consumes from RabbitMQ queues |
| **Mock BPP RabbitMQ** | Queue-based | - | Consumes from RabbitMQ queues |

## Accessing Services

### Port Forwarding

To access services from your local machine:

```bash
# Port forward RabbitMQ Management UI
kubectl port-forward svc/rabbitmq 15672:15672 -n ev-charging-sandbox

# Port forward Mock Registry
kubectl port-forward svc/mock-registry 3030:3030 -n ev-charging-sandbox

# Port forward Mock CDS
kubectl port-forward svc/mock-cds 8082:8082 -n ev-charging-sandbox

# Port forward ONIX BAP Plugin
kubectl port-forward svc/onix-bap-plugin-rabbitmq 8001:8001 -n ev-charging-sandbox

# Port forward ONIX BPP Plugin
kubectl port-forward svc/onix-bpp-plugin-rabbitmq 8002:8002 -n ev-charging-sandbox
```

### Using Ingress (if configured)

If you have an Ingress controller configured, you can access services via Ingress routes.

## Message Flow

### Service Discovery Flow (Phase 1)

1. **BAP Application** → Publishes `discover` request to RabbitMQ with routing key `bap.discover`
2. **ONIX BAP Plugin** → Consumes message, routes to **Mock CDS** via HTTP
3. **Mock CDS** → Broadcasts discover to all registered BPPs
4. **ONIX BPP Plugin** → Receives discover from CDS, publishes to RabbitMQ with routing key `bpp.discover` (to BPP Backend)
5. **Mock BPP RabbitMQ** → Consumes `bpp.discover`, processes, publishes `on_discover` response
6. **ONIX BPP Plugin** → Routes `on_discover` response to **Mock CDS** via HTTP
7. **Mock CDS** → Aggregates responses, sends to **ONIX BAP Plugin**
8. **ONIX BAP Plugin** → Publishes aggregated response to RabbitMQ with routing key `bap.on_discover`
9. **Mock BAP RabbitMQ** → Consumes `bap.on_discover` callback

### Transaction Flow (Phase 2+)

1. **BAP Application** → Publishes `select/init/confirm` request to RabbitMQ with routing key `bap.select/bap.init/bap.confirm`
2. **ONIX BAP Plugin** → Consumes message, routes directly to **ONIX BPP Plugin** (bypasses CDS)
3. **ONIX BPP Plugin** → Publishes to RabbitMQ with routing key `bpp.select/bpp.init/bpp.confirm` (to BPP Backend)
4. **Mock BPP RabbitMQ** → Consumes request, processes, publishes response
5. **ONIX BPP Plugin** → Routes callback to **ONIX BAP Plugin**
6. **ONIX BAP Plugin** → Publishes callback to RabbitMQ with routing key `bap.on_select/bap.on_init/bap.on_confirm`
7. **Mock BAP RabbitMQ** → Consumes callback

## RabbitMQ Queue Structure

### Exchange
- **Name**: `beckn_exchange`
- **Type**: Topic exchange (allows routing based on routing keys)

### BAP Queues and Routing Keys
- **Queue**: `bap_caller_queue`
- **Routing Keys**:
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

### BPP Queues and Routing Keys
- **Queue**: `bpp_caller_queue`
- **Routing Keys**:
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

## RabbitMQ Management UI

The RabbitMQ Management Plugin is enabled by default and provides a web-based UI for monitoring and managing RabbitMQ.

### Accessing RabbitMQ Management UI

1. **Port forward the service**:
   ```bash
   kubectl port-forward svc/rabbitmq 15672:15672 -n ev-charging-sandbox
   ```

2. **Open the Management UI**:
   - URL: `http://localhost:15672`
   - Username: `admin` (default, configured in values.yaml)
   - Password: `admin` (default, configured in values.yaml)

### Features

- View exchanges and queues
- Browse messages
- Monitor consumer connections
- View cluster metrics
- Manage bindings and routing

## Publishing Test Messages

The `message/` directory contains example JSON messages and shell scripts for publishing test messages to RabbitMQ queues.

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
# From sandbox/helm/rabbitmq directory
./populate-schemas.sh

# Or specify custom release names
RELEASE_BAP=my-rabbitmq-bap RELEASE_BPP=my-rabbitmq-bpp ./populate-schemas.sh

# Or specify custom namespace
NAMESPACE=my-namespace ./populate-schemas.sh
```

**Option 2: Manual ConfigMap creation**

```bash
# Create schemas ConfigMap for BAP
kubectl create configmap ev-charging-rabbitmq-bap-onix-rabbitmq-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Create schemas ConfigMap for BPP
kubectl create configmap ev-charging-rabbitmq-bpp-onix-rabbitmq-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new schemas
kubectl delete pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-rabbitmq-bap
kubectl delete pod -n ev-charging-sandbox -l component=bpp,app.kubernetes.io/instance=ev-charging-rabbitmq-bpp
```

### Verifying Schemas

After deployment, verify schemas are correctly mounted:

```bash
# Check if schemas are present in BAP pod
kubectl exec -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-rabbitmq-bap -o jsonpath='{.items[0].metadata.name}') \
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
   kubectl delete pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-rabbitmq-bap
   kubectl delete pod -n ev-charging-sandbox -l component=bpp,app.kubernetes.io/instance=ev-charging-rabbitmq-bpp
   ```

### Schema Validation Errors

If you encounter errors like `schema validation failed: schema not found for domain: beckn.one_deg_ev-charging`:

1. **Verify ConfigMap exists:**
   ```bash
   kubectl get configmap -n ev-charging-sandbox | grep schemas
   ```

2. **Check ConfigMap contents:**
   ```bash
   kubectl get configmap ev-charging-rabbitmq-bap-onix-rabbitmq-schemas \
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
     $(kubectl get pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-rabbitmq-bap -o jsonpath='{.items[0].metadata.name}') \
     | grep -i schema
   ```

For more details, see [Schema Setup Guide](../SCHEMA_SETUP.md).

## Troubleshooting

### Check Pod Status

```bash
# Check all pods
kubectl get pods -n ev-charging-sandbox

# Check specific component
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bap
kubectl get pods -n ev-charging-sandbox -l app.kubernetes.io/component=bpp

# Check pod logs
kubectl logs -n ev-charging-sandbox <pod-name>
kubectl logs -f -n ev-charging-sandbox <pod-name>  # Follow logs
```

### Check RabbitMQ Queues

```bash
# Port forward RabbitMQ Management UI and check queues via web UI
kubectl port-forward svc/rabbitmq 15672:15672 -n ev-charging-sandbox

# Or use kubectl exec to access RabbitMQ pod
kubectl exec -it -n ev-charging-sandbox <rabbitmq-pod-name> -- rabbitmqctl list_queues
kubectl exec -it -n ev-charging-sandbox <rabbitmq-pod-name> -- rabbitmqctl list_exchanges
kubectl exec -it -n ev-charging-sandbox <rabbitmq-pod-name> -- rabbitmqctl list_bindings
```

### Check Services

```bash
# List all services
kubectl get svc -n ev-charging-sandbox

# Check service endpoints
kubectl get endpoints -n ev-charging-sandbox
```

### Common Issues

1. **RabbitMQ pod not starting**: Check resource limits and node capacity
2. **Queues not created**: Verify RabbitMQ exchange and queue configuration in adapter config
3. **Messages not consumed**: Check consumer configuration and pod logs
4. **Network issues**: Verify service names are correct in configuration
5. **Connection refused**: Ensure RabbitMQ service is accessible and credentials are correct

## Uninstalling

```bash
# Uninstall BAP (default namespace)
helm uninstall ev-charging-rabbitmq-bap

# Uninstall BPP (default namespace)
helm uninstall ev-charging-rabbitmq-bpp

# Uninstall from specific namespace
helm uninstall ev-charging-rabbitmq-bap --namespace ev-charging-sandbox
helm uninstall ev-charging-rabbitmq-bpp --namespace ev-charging-sandbox

# Remove all resources (if needed)
kubectl delete all -l app.kubernetes.io/name=onix-rabbitmq
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-rabbitmq  # If using namespace
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Main Helm Chart README](../../../../helm/rabbitmq/README.md) - Detailed Helm chart documentation
- [Docker Sandbox README](../../../docker/rabbitmq/README.md) - Docker Compose equivalent setup

## Notes

- Service names in Kubernetes use DNS resolution within the cluster
- All services communicate using Kubernetes service names (e.g., `rabbitmq:5672`)
- Configuration is managed through Helm values files and ConfigMaps
- Mock RabbitMQ services run in queue-only mode (no external HTTP ports)
- Production deployments should use proper secrets management for keys and credentials
- RabbitMQ requires persistent storage for production deployments
- Default RabbitMQ credentials are `admin/admin` - change these in production
