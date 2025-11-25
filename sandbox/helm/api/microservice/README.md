# EV Charging Sandbox - Microservice Architecture Helm Setup

This directory contains Helm values files for deploying a complete EV Charging sandbox environment using Kubernetes/Helm. The setup includes API adapters (BAP and BPP), mock services (CDS, Registry, multiple BAP and BPP instances), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol in a **microservice architecture**. In this architecture, each endpoint routes to different mock services, allowing for:

- **Centralized Management**: Single adapter service handles all endpoints
- **Flexible Routing**: Each endpoint can route to different mock services for testing
- **Easy Configuration**: Routing changes only require updating YAML files
- **Resource Efficiency**: Single service instance handles all endpoints
- **Kubernetes Native**: Deployed using Helm charts for easy management

The architecture includes:

- **ONIX Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider)
- **Mock Services**: Multiple simulated services (one per endpoint) for testing without real implementations
- **Supporting Services**: Redis for caching and state management

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to Docker images (pulled automatically from Docker Hub)

## Quick Start

### Deploy Complete Sandbox Environment (One Command)

Deploy BAP, BPP, and all mock services in one go:

**Deploy from sandbox/helm/api/microservice directory**

```bash
# IMPORTANT: Run from sandbox/helm/api/microservice directory
# Verify you're in the right directory (should see values-sandbox.yaml)
ls values-sandbox.yaml

# Deploy BAP and BPP adapters (both required)
# To customize pod names (e.g., replace "microservice" with "on_discover"), add:
# --set nameOverride="onix-api-on_discover"
# This will create pod names like: ev-charging-bap-onix-api-on_discover-bap-xxxxx

# Deploy BAP adapter
helm upgrade --install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP adapter
helm upgrade --install ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox

# Deploy all mock services (all with ev-charging- prefix)
# Note: BAP services use on_* prefix (on_discover, on_select, etc.) as they receive callbacks
helm upgrade --install ev-charging-mock-registry ../../../mock-registry \
  --set fullnameOverride=ev-charging-mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-cds ../../../mock-cds \
  --set fullnameOverride=ev-charging-mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-discover ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-discover \
  --set service.port=9001 \
  --set service.targetPort=9001 \
  --set config.server.port=":9001" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-select ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-select \
  --set service.port=9002 \
  --set service.targetPort=9002 \
  --set config.server.port=":9002" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-init ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-init \
  --set service.port=9003 \
  --set service.targetPort=9003 \
  --set config.server.port=":9003" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-confirm ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-confirm \
  --set service.port=9004 \
  --set service.targetPort=9004 \
  --set config.server.port=":9004" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-status ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-status \
  --set service.port=9005 \
  --set service.targetPort=9005 \
  --set config.server.port=":9005" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-track ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-track \
  --set service.port=9006 \
  --set service.targetPort=9006 \
  --set config.server.port=":9006" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-cancel ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-cancel \
  --set service.port=9007 \
  --set service.targetPort=9007 \
  --set config.server.port=":9007" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-update ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-update \
  --set service.port=9008 \
  --set service.targetPort=9008 \
  --set config.server.port=":9008" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-rating ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-rating \
  --set service.port=9009 \
  --set service.targetPort=9009 \
  --set config.server.port=":9009" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-support ../../../mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-support \
  --set service.port=9010 \
  --set service.targetPort=9010 \
  --set config.server.port=":9010" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-discover ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-discover \
  --set service.port=9011 \
  --set service.targetPort=9011 \
  --set config.server.port=":9011" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-select ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-select \
  --set service.port=9012 \
  --set service.targetPort=9012 \
  --set config.server.port=":9012" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-init ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-init \
  --set service.port=9013 \
  --set service.targetPort=9013 \
  --set config.server.port=":9013" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-confirm ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-confirm \
  --set service.port=9014 \
  --set service.targetPort=9014 \
  --set config.server.port=":9014" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-status ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-status \
  --set service.port=9015 \
  --set service.targetPort=9015 \
  --set config.server.port=":9015" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-track ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-track \
  --set service.port=9016 \
  --set service.targetPort=9016 \
  --set config.server.port=":9016" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-cancel ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-cancel \
  --set service.port=9017 \
  --set service.targetPort=9017 \
  --set config.server.port=":9017" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-update ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-update \
  --set service.port=9018 \
  --set service.targetPort=9018 \
  --set config.server.port=":9018" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-rating ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-rating \
  --set service.port=9019 \
  --set service.targetPort=9019 \
  --set config.server.port=":9019" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-support ../../../mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-support \
  --set service.port=9020 \
  --set service.targetPort=9020 \
  --set config.server.port=":9020" \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox

# Watch pod status (optional)
watch -n 2 'kubectl get pods -n ev-charging-sandbox'
```

### Deploy BAP Component

```bash
# Navigate to this directory
cd sandbox/helm/api/microservice

# Deploy BAP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-bap-1 ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-bap-2 ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
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
helm install ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
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
helm upgrade --install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# All kubectl commands should include -n flag when using namespace
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox
kubectl logs -n ev-charging-sandbox <pod-name>
```

### Mock Services Deployment

Mock services (mock-registry, mock-cds, and multiple mock-bap/mock-bpp instances) can be deployed using their individual Helm charts. Each mock service has its own Helm chart in the `sandbox/` directory.

#### Deploy All Mock Services with Helm (Recommended)

```bash
# Navigate to sandbox directory
cd ../../..

# Deploy mock-registry (with ev-charging- prefix)
helm upgrade --install ev-charging-mock-registry ./sandbox/mock-registry \
  --set fullnameOverride=ev-charging-mock-registry \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy mock-cds (with ev-charging- prefix)
helm upgrade --install ev-charging-mock-cds ./sandbox/mock-cds \
  --set fullnameOverride=ev-charging-mock-cds \
  --namespace ev-charging-sandbox

# Deploy mock-bap services (10 endpoints, all with ev-charging- prefix)
# Note: BAP services use on_* prefix (on_discover, on_select, etc.) as they receive callbacks
# Each service needs unique fullnameOverride to avoid resource name conflicts
helm upgrade --install ev-charging-mock-bap-on-discover ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-discover \
  --set service.port=9001 \
  --set service.targetPort=9001 \
  --set config.server.port=":9001" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-select ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-select \
  --set service.port=9002 \
  --set service.targetPort=9002 \
  --set config.server.port=":9002" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-init ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-init \
  --set service.port=9003 \
  --set service.targetPort=9003 \
  --set config.server.port=":9003" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-confirm ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-confirm \
  --set service.port=9004 \
  --set service.targetPort=9004 \
  --set config.server.port=":9004" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-status ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-status \
  --set service.port=9005 \
  --set service.targetPort=9005 \
  --set config.server.port=":9005" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-track ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-track \
  --set service.port=9006 \
  --set service.targetPort=9006 \
  --set config.server.port=":9006" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-cancel ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-cancel \
  --set service.port=9007 \
  --set service.targetPort=9007 \
  --set config.server.port=":9007" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-update ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-update \
  --set service.port=9008 \
  --set service.targetPort=9008 \
  --set config.server.port=":9008" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-rating ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-rating \
  --set service.port=9009 \
  --set service.targetPort=9009 \
  --set config.server.port=":9009" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bap-on-support ./sandbox/mock-bap \
  --set fullnameOverride=ev-charging-mock-bap-on-support \
  --set service.port=9010 \
  --set service.targetPort=9010 \
  --set config.server.port=":9010" \
  --namespace ev-charging-sandbox

# Deploy mock-bpp services (10 endpoints, all with ev-charging- prefix)
# Note: Each service needs unique fullnameOverride to avoid resource name conflicts
helm upgrade --install ev-charging-mock-bpp-discover ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-discover \
  --set service.port=9011 \
  --set service.targetPort=9011 \
  --set config.server.port=":9011" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-select ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-select \
  --set service.port=9012 \
  --set service.targetPort=9012 \
  --set config.server.port=":9012" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-init ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-init \
  --set service.port=9013 \
  --set service.targetPort=9013 \
  --set config.server.port=":9013" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-confirm ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-confirm \
  --set service.port=9014 \
  --set service.targetPort=9014 \
  --set config.server.port=":9014" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-status ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-status \
  --set service.port=9015 \
  --set service.targetPort=9015 \
  --set config.server.port=":9015" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-track ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-track \
  --set service.port=9016 \
  --set service.targetPort=9016 \
  --set config.server.port=":9016" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-cancel ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-cancel \
  --set service.port=9017 \
  --set service.targetPort=9017 \
  --set config.server.port=":9017" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-update ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-update \
  --set service.port=9018 \
  --set service.targetPort=9018 \
  --set config.server.port=":9018" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-rating ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-rating \
  --set service.port=9019 \
  --set service.targetPort=9019 \
  --set config.server.port=":9019" \
  --namespace ev-charging-sandbox && \
helm upgrade --install ev-charging-mock-bpp-support ./sandbox/mock-bpp \
  --set fullnameOverride=ev-charging-mock-bpp-support \
  --set service.port=9020 \
  --set service.targetPort=9020 \
  --set config.server.port=":9020" \
  --namespace ev-charging-sandbox

# Verify all mock services are running
kubectl get pods -n ev-charging-sandbox | grep ev-charging-mock
kubectl get svc -n ev-charging-sandbox | grep ev-charging-mock
```

#### Alternative: Deploy Mock Services via Docker Compose

If you're running Kubernetes locally (e.g., minikube, kind) and prefer Docker Compose:

```bash
# From the sandbox root directory
cd ../../docker/api/microservice

# Deploy all mock services
docker-compose up -d mock-registry mock-cds mock-bap mock-bpp

# Verify services are running
docker-compose ps
```

**Note**: Each mock service Helm chart includes:
- Deployment with health probes
- Service with ClusterIP (configurable)
- ConfigMap with service configuration
- Resource limits and requests

### Installing Multiple Instances

If you need multiple instances of the same component in the same namespace, use different release names:

```bash
# Install first BAP instance
helm install ev-charging-bap-1 ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install second BAP instance with different name
helm install ev-charging-bap-2 ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Each instance will have different service names and can run on different ports
```

## Services

### Core Services

1. **redis-onix-bap** (Port: 6379)
   - Redis cache for the BAP adapter
   - Used for storing transaction state, caching registry lookups, and session management

2. **redis-onix-bpp** (Port: 6380)
   - Redis cache for the BPP adapter
   - Used for storing transaction state, caching registry lookups, and session management

3. **onix-bap-plugin** (Port: 8001)
   - ONIX protocol adapter for BAP (Buyer App Provider)
   - Handles protocol compliance, signing, validation, and routing for BAP transactions
   - **Caller Endpoint**: `/bap/caller/` - Entry point for requests from BAP application
   - **Receiver Endpoint**: `/bap/receiver/` - Receives callbacks from CDS and BPPs

4. **onix-bpp-plugin** (Port: 8002)
   - ONIX protocol adapter for BPP (Buyer Platform Provider)
   - Handles protocol compliance, signing, validation, and routing for BPP transactions
   - **Caller Endpoint**: `/bpp/caller/` - Sends responses to CDS and BAPs
   - **Receiver Endpoint**: `/bpp/receiver/` - Receives requests from CDS and BAPs

### Mock Services

5. **ev-charging-mock-registry** (Port: 3030)
   - Mock implementation of the network registry service
   - Maintains a registry of all BAPs, BPPs, and CDS services on the network
   - Provides subscriber lookup and key management functionality

6. **ev-charging-mock-cds** (Port: 8082)
   - Mock Catalog Discovery Service (CDS)
   - Aggregates discover requests from BAPs and broadcasts to registered BPPs
   - Collects and aggregates responses from multiple BPPs
   - Handles signature verification and signing

7. **Mock BAP Services** (Ports: 9001-9010)
   - Multiple mock BAP backend services, one per endpoint (using `on_*` prefix for callback endpoints):
     - `ev-charging-mock-bap-on-discover` (Port: 9001) - Handles on_discover callbacks
     - `ev-charging-mock-bap-on-select` (Port: 9002) - Handles on_select callbacks
     - `ev-charging-mock-bap-on-init` (Port: 9003) - Handles on_init callbacks
     - `ev-charging-mock-bap-on-confirm` (Port: 9004) - Handles on_confirm callbacks
     - `ev-charging-mock-bap-on-status` (Port: 9005) - Handles on_status callbacks
     - `ev-charging-mock-bap-on-track` (Port: 9006) - Handles on_track callbacks
     - `ev-charging-mock-bap-on-cancel` (Port: 9007) - Handles on_cancel callbacks
     - `ev-charging-mock-bap-on-update` (Port: 9008) - Handles on_update callbacks
     - `ev-charging-mock-bap-on-rating` (Port: 9009) - Handles on_rating callbacks
     - `ev-charging-mock-bap-on-support` (Port: 9010) - Handles on_support callbacks
   - Each service simulates a Buyer App Provider application endpoint
   - Receives callbacks from the ONIX adapter based on routing configuration

8. **Mock BPP Services** (Ports: 9011-9020)
   - Multiple mock BPP backend services, one per endpoint:
     - `ev-charging-mock-bpp-discover` (Port: 9011) - Handles discover requests
     - `ev-charging-mock-bpp-select` (Port: 9012) - Handles select requests
     - `ev-charging-mock-bpp-init` (Port: 9013) - Handles init requests
     - `ev-charging-mock-bpp-confirm` (Port: 9014) - Handles confirm requests
     - `ev-charging-mock-bpp-status` (Port: 9015) - Handles status requests
     - `ev-charging-mock-bpp-track` (Port: 9016) - Handles track requests
     - `ev-charging-mock-bpp-cancel` (Port: 9017) - Handles cancel requests
     - `ev-charging-mock-bpp-update` (Port: 9018) - Handles update requests
     - `ev-charging-mock-bpp-rating` (Port: 9019) - Handles rating requests
     - `ev-charging-mock-bpp-support` (Port: 9020) - Handles support requests
   - Each service simulates a Buyer Platform Provider application endpoint
   - Handles requests from the ONIX adapter based on routing configuration

## Configuration Files

### `values-sandbox.yaml`

This file contains sandbox-specific overrides for the Helm chart. It includes:

- Mock services configuration (registry, CDS, BAP, BPP)
- Adapter configuration with Kubernetes service names
- Routing configuration for microservice architecture

**Key Features**:
- Uses Kubernetes service names instead of container names
- Includes all mock service configurations
- Pre-configured routing for microservice architecture (one service per endpoint)
- **Service Exposure**: BAP and BPP ONIX plugins are exposed externally (LoadBalancer), while mock services remain internal (ClusterIP)

## Service Endpoints

### Service Exposure Configuration

**External Services (Exposed Outside Cluster):**
- **BAP ONIX Plugin** - Exposed via LoadBalancer/NodePort (port 8001)
- **BPP ONIX Plugin** - Exposed via LoadBalancer/NodePort (port 8002)

**Internal Services (ClusterIP Only):**
- **Mock Registry** - ClusterIP (port 3030) - Internal only
- **Mock CDS** - ClusterIP (port 8082) - Internal only
- **Mock BAP Services** - ClusterIP (ports 9001-9010) - Internal only
- **Mock BPP Services** - ClusterIP (ports 9011-9020) - Internal only
- **Redis** - ClusterIP (port 6379/6380) - Internal only

This configuration ensures that:
- BAP and BPP ONIX plugins are accessible from outside the cluster for API testing
- All mock services and Redis remain secure within the cluster
- Inter-service communication uses Kubernetes internal DNS

### Service Details

Once all services are deployed, you can access them via Kubernetes services:

| Service | Service Name | Port | Type | Access |
|---------|--------------|------|------|--------|
| **ONIX BAP** | `ev-charging-bap-onix-api-microservice-bap-service` | 8001 | LoadBalancer | External: `http://<external-ip>:8001`<br>Internal: `http://ev-charging-bap-onix-api-microservice-bap-service:8001` |
| | `/bap/caller/{action}` | | | Send requests from BAP |
| | `/bap/receiver/{action}` | | | Receive callbacks |
| **ONIX BPP** | `ev-charging-bpp-onix-api-microservice-bpp-service` | 8002 | LoadBalancer | External: `http://<external-ip>:8002`<br>Internal: `http://ev-charging-bpp-onix-api-microservice-bpp-service:8002` |
| | `/bpp/caller/{action}` | | | Send responses |
| | `/bpp/receiver/{action}` | | | Receive requests |
| **Mock Registry** | `ev-charging-mock-registry` | 3030 | ClusterIP | Internal only: `http://ev-charging-mock-registry:3030` |
| **Mock CDS** | `ev-charging-mock-cds` | 8082 | ClusterIP | Internal only: `http://ev-charging-mock-cds:8082` |
| **Mock BAP Services** | `ev-charging-mock-bap-on-discover` | 9001 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-discover:9001` |
| | `ev-charging-mock-bap-on-select` | 9002 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-select:9002` |
| | `ev-charging-mock-bap-on-init` | 9003 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-init:9003` |
| | `ev-charging-mock-bap-on-confirm` | 9004 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-confirm:9004` |
| | `ev-charging-mock-bap-on-status` | 9005 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-status:9005` |
| | `ev-charging-mock-bap-on-track` | 9006 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-track:9006` |
| | `ev-charging-mock-bap-on-cancel` | 9007 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-cancel:9007` |
| | `ev-charging-mock-bap-on-update` | 9008 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-update:9008` |
| | `ev-charging-mock-bap-on-rating` | 9009 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-rating:9009` |
| | `ev-charging-mock-bap-on-support` | 9010 | ClusterIP | Internal only: `http://ev-charging-mock-bap-on-support:9010` |
| **Mock BPP Services** | `ev-charging-mock-bpp-discover` | 9011 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-discover:9011` |
| | `ev-charging-mock-bpp-select` | 9012 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-select:9012` |
| | `ev-charging-mock-bpp-init` | 9013 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-init:9013` |
| | `ev-charging-mock-bpp-confirm` | 9014 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-confirm:9014` |
| | `ev-charging-mock-bpp-status` | 9015 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-status:9015` |
| | `ev-charging-mock-bpp-track` | 9016 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-track:9016` |
| | `ev-charging-mock-bpp-cancel` | 9017 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-cancel:9017` |
| | `ev-charging-mock-bpp-update` | 9018 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-update:9018` |
| | `ev-charging-mock-bpp-rating` | 9019 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-rating:9019` |
| | `ev-charging-mock-bpp-support` | 9020 | ClusterIP | Internal only: `http://ev-charging-mock-bpp-support:9020` |
| **Redis BAP** | `ev-charging-bap-onix-api-microservice-redis` | 6379 | ClusterIP | Internal only: `ev-charging-bap-onix-api-microservice-redis:6379` |
| **Redis BPP** | `ev-charging-bpp-onix-api-microservice-redis` | 6379 | ClusterIP | Internal only: `ev-charging-bpp-onix-api-microservice-redis:6379` |

### Getting External IP Addresses

After deployment, get the external IP addresses for BAP and BPP:

```bash
# Get external IP for BAP service
kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-microservice-bap-service

# Get external IP for BPP service
kubectl get svc -n ev-charging-sandbox ev-charging-bpp-onix-api-microservice-bpp-service

# Or get both at once
kubectl get svc -n ev-charging-sandbox -l 'component in (bap,bpp)'

# For NodePort type, get the node IP and port
kubectl get nodes -o wide  # Get node IP
kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-microservice-bap-service -o jsonpath='{.spec.ports[0].nodePort}'
```

## Accessing Services

### External Access (LoadBalancer/NodePort)

Since BAP and BPP services are exposed externally via LoadBalancer, you can access them directly without port forwarding:

```bash
# Get external IP addresses
kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-microservice-bap-service
kubectl get svc -n ev-charging-sandbox ev-charging-bpp-onix-api-microservice-bpp-service

# Access BAP directly (replace <external-ip> with actual IP)
curl http://<external-ip>:8001/health

# Access BPP directly (replace <external-ip> with actual IP)
curl http://<external-ip>:8002/health
```

**Note**: Mock services (registry, CDS, mock-bap, mock-bpp) are ClusterIP only and not accessible from outside the cluster. They communicate internally with the ONIX plugins.

### Port Forwarding (Alternative)

If you prefer port forwarding or if LoadBalancer is not available (e.g., minikube), you can use port forwarding:

**Important**: You need to run port forwarding commands in separate terminal windows/tabs to keep them running.

```bash
# Port forward BAP adapter (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-microservice-bap-service 8001:8001

# Port forward BPP adapter (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-microservice-bpp-service 8002:8002

# Port forward Mock Registry (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-registry 3030:3030

# Port forward Mock CDS (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-cds 8082:8082

# Port forward Mock BAP Services (run in separate terminals or background)
# Note: BAP services use on_* prefix (on_discover, on_select, etc.) as they receive callbacks
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-discover 9001:9001 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-select 9002:9002 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-init 9003:9003 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-confirm 9004:9004 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-status 9005:9005 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-track 9006:9006 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-cancel 9007:9007 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-update 9008:9008 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-rating 9009:9009 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap-on-support 9010:9010 &

# Port forward Mock BPP Services (run in separate terminals or background)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-discover 9011:9011 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-select 9012:9012 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-init 9013:9013 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-confirm 9014:9014 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-status 9015:9015 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-track 9016:9016 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-cancel 9017:9017 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-update 9018:9018 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-rating 9019:9019 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp-support 9020:9020 &
```

**Or use the provided port-forward script:**

```bash
# Run the port-forward script (manages all port forwards)
./port-forward.sh

# Or run all port forwards manually in background
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-microservice-bap-service 8001:8001 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-microservice-bpp-service 8002:8002 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-registry 3030:3030 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-cds 8082:8082 &
# ... (all mock services with ev-charging- prefix and on_* for BAP)

# To stop all port forwards
pkill -f "kubectl port-forward"
```

### Postman Environment Files

Postman environment files are provided for easy API testing:

- **`bap-env.json`**: BAP environment variables for Postman
- **`bpp-env.json`**: BPP environment variables for Postman

**To use in Postman:**

1. Import the environment file:
   - Open Postman
   - Click "Import" → Select `bap-env.json` or `bpp-env.json`
   - The environment will be added to your Postman workspace

2. **Access the services:**
   
   **Option A: Direct external access (if LoadBalancer is configured):**
   ```bash
   # Get external IP
   kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-microservice-bap-service
   # Use the EXTERNAL-IP in Postman environment variables
   ```
   
   **Option B: Port forwarding (if LoadBalancer not available):**
   ```bash
   # For BAP endpoints
   kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-microservice-bap-service 8001:8001
   
   # For BPP endpoints (in another terminal)
   kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-microservice-bpp-service 8002:8002
   ```

3. Select the imported environment in Postman and start making API calls.

**Example API Calls (after port forwarding):**

```bash
# Test BAP health endpoint
curl http://localhost:8001/health

# Test BAP caller endpoint (recommended for testing)
# BAP caller endpoints accept unsigned requests for testing
curl -X POST http://localhost:8001/bap/caller/select \
  -H "Content-Type: application/json" \
  -d '{"context": {...}, "message": {...}}'

# Test BPP health endpoint
curl http://localhost:8002/health

# Note: BPP caller endpoints (/bpp/caller/*) require properly signed requests
# For testing BPP responses, use the BAP caller endpoints instead, which will
# route through the system and trigger BPP responses automatically
```

### Using Ingress (if configured)

If you have an Ingress controller configured, you can access services via Ingress routes instead of port forwarding.

## Updating Configuration

### Update Values

```bash
# Update BAP deployment (or use upgrade --install for idempotent updates)
helm upgrade ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Update BPP deployment (or use upgrade --install for idempotent updates)
helm upgrade ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox

# Alternative: Use upgrade --install for idempotent operations (installs if not exists, upgrades if exists)
helm upgrade --install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace
```

### Modify Routing

Edit `values-sandbox.yaml` and update the `config.routing` sections, then upgrade the Helm release.

## Schema Configuration

The ONIX adapters require JSON schemas for validation. Schemas are automatically populated from the `schemas/beckn.one_deg_ev-charging/v2.0.0/` directory into Kubernetes ConfigMaps.

### Populating Schemas

Schemas need to be populated into ConfigMaps before pods can use them:

**Option 1: Using the helper script (Recommended)**

```bash
# From sandbox/helm/api/microservice directory
./populate-schemas.sh

# Or specify custom release names
RELEASE_BAP=my-bap RELEASE_BPP=my-bpp ./populate-schemas.sh

# Or specify custom namespace
NAMESPACE=my-namespace ./populate-schemas.sh
```

**Option 2: Manual ConfigMap creation**

```bash
# Create schemas ConfigMap for BAP
kubectl create configmap ev-charging-microservice-bap-onix-api-microservice-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Create schemas ConfigMap for BPP
kubectl create configmap ev-charging-microservice-bpp-onix-api-microservice-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new schemas
kubectl delete pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-microservice-bap
kubectl delete pod -n ev-charging-sandbox -l component=bpp,app.kubernetes.io/instance=ev-charging-microservice-bpp
```

### Verifying Schemas

After deployment, verify schemas are correctly mounted:

```bash
# Check if schemas are present in BAP pod
kubectl exec -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-microservice-bap -o jsonpath='{.items[0].metadata.name}') \
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
   kubectl delete pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-microservice-bap
   kubectl delete pod -n ev-charging-sandbox -l component=bpp,app.kubernetes.io/instance=ev-charging-microservice-bpp
   ```

### Schema Validation Errors

If you encounter errors like `schema validation failed: schema not found for domain: beckn.one_deg_ev-charging`:

1. **Verify ConfigMap exists:**
   ```bash
   kubectl get configmap -n ev-charging-sandbox | grep schemas
   ```

2. **Check ConfigMap contents:**
   ```bash
   kubectl get configmap ev-charging-microservice-bap-onix-api-microservice-schemas \
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
     $(kubectl get pod -n ev-charging-sandbox -l component=bap,app.kubernetes.io/instance=ev-charging-microservice-bap -o jsonpath='{.items[0].metadata.name}') \
     | grep -i schema
   ```

For more details, see [Schema Setup Guide](../../SCHEMA_SETUP.md).

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
kubectl logs -n ev-charging-sandbox -l app.kubernetes.io/component=bap  # Logs for all BAP pods
kubectl logs -n ev-charging-sandbox -l app.kubernetes.io/component=bpp  # Logs for all BPP pods
```

### Check Services

```bash
# List all services
kubectl get svc -n ev-charging-sandbox

# Check service endpoints
kubectl get endpoints -n ev-charging-sandbox

# Check Redis services
kubectl get svc -n ev-charging-sandbox | grep redis
```

### Check ConfigMaps

```bash
# List configmaps
kubectl get configmap -n ev-charging-sandbox

# View configmap content
kubectl get configmap <configmap-name> -n ev-charging-sandbox -o yaml

# View adapter configuration
kubectl get configmap ev-charging-bap-onix-api-microservice-bap-adapter -n ev-charging-sandbox -o jsonpath='{.data.adapter\.yaml}'
kubectl get configmap ev-charging-bpp-onix-api-microservice-bpp-adapter -n ev-charging-sandbox -o jsonpath='{.data.adapter\.yaml}'
```

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Service not accessible**: Verify service selectors match pod labels
3. **Configuration errors**: Check ConfigMap content and pod logs
4. **Network issues**: Verify service names are correct in configuration
5. **401 Unauthorized / Signature Validation Error**:
   - **Issue**: BPP caller endpoints (`/bpp/caller/*`) require properly signed requests
   - **Solution**: For testing, use BAP caller endpoints (`/bap/caller/*`) instead, which will trigger the full flow including BPP responses
   - **Alternative**: Remove any Authorization header from Postman requests if testing BPP caller directly, or ensure requests are properly signed according to Beckn protocol
   - **Example**: Use `POST http://localhost:8001/bap/caller/select` instead of `POST http://localhost:8002/bpp/caller/on_update`

## Uninstalling

```bash
# Uninstall BAP (default namespace)
helm uninstall ev-charging-bap

# Uninstall BPP (default namespace)
helm uninstall ev-charging-bpp

# Uninstall from specific namespace
helm uninstall ev-charging-bap --namespace ev-charging-sandbox
helm uninstall ev-charging-bpp --namespace ev-charging-sandbox

# Remove all resources (if needed)
kubectl delete all -l app.kubernetes.io/name=onix-api-microservice
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-microservice  # If using namespace
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Main Helm Chart README](../../../../helm/api/microservice/README.md) - Detailed Helm chart documentation
- [Docker Sandbox README](../../../docker/api/microservice/README.md) - Docker Compose equivalent setup

## Notes

- Service names in Kubernetes use DNS resolution within the cluster
- All services communicate using Kubernetes service names (e.g., `ev-charging-mock-registry:3030`)
- Configuration is managed through Helm values files and ConfigMaps
- **Microservice Architecture**: Each endpoint has its own mock service instance:
  - 10 mock-bap services (ev-charging-mock-bap-on-discover through ev-charging-mock-bap-on-support) - using `on_*` prefix for callbacks
  - 10 mock-bpp services (ev-charging-mock-bpp-discover through ev-charging-mock-bpp-support)
- **Naming Convention**: All services use `ev-charging-` prefix for consistency
- Production deployments should use proper secrets management for keys and credentials

