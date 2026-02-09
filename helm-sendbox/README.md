# EV Charging Sandbox - Monolithic Architecture Helm Setup

This directory contains Helm values files for deploying a complete EV Charging sandbox environment using Kubernetes/Helm. The setup includes API adapters (BAP and BPP), mock services (CDS, Registry, single BAP and BPP instances), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol in a **monolithic architecture**. In this architecture, a single mock service handles all endpoints, allowing for:

- **Simplified Deployment**: Single service instance handles all endpoints
- **Easier Testing**: All endpoints route to one service
- **Resource Efficiency**: Fewer services to manage
- **Kubernetes Native**: Deployed using Helm charts for easy management

The architecture includes:

- **ONIX Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider)
- **Mock Services**: Single simulated services for BAP and BPP that handle all endpoints
- **Supporting Services**: Redis for caching and state management

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to Docker images (pulled automatically from Docker Hub)

## Quick Start

### Deploy Complete Sandbox Environment (All Services)

Deploy the complete sandbox environment with all services (BAP, BPP, and all mock services) in one go:

**🚀 Quick Deploy - All Services**

**Option 1: Using the Deployment Script (Recommended)**

The easiest way to deploy all services is using the provided script:

```bash
# Run from any directory
cd helm-sendbox
./deploy-all.sh
```

The script automatically:
- Verifies all paths exist
- Creates the namespace if needed
- Deploys all services (BAP, BPP, and mock services)
- Shows deployment status

**Option 2: Manual Deployment**

**IMPORTANT**: You must run these commands from the `helm-sendbox` directory.

```bash
# Navigate to helm-sendbox directory (from project root)
cd helm-sendbox

# Verify you're in the right directory (should see values-sandbox.yaml)
pwd
# Should output: .../ubc-ev-sandbox/helm-sendbox
ls values-sandbox.yaml

# Deploy all services (BAP, BPP, and mock services)
helm upgrade --install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-registry ../mock/mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-cds ../mock/mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bap ../mock/mock-bap \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bpp ../mock/mock-bpp \
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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

# Deploy all services using absolute paths
helm upgrade --install onix-bap ${PROJECT_ROOT}/helm \
  -f ${PROJECT_ROOT}/helm/values-bap.yaml \
  -f ${PROJECT_ROOT}/helm-sendbox/values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install onix-bpp ${PROJECT_ROOT}/helm \
  -f ${PROJECT_ROOT}/helm/values-bpp.yaml \
  -f ${PROJECT_ROOT}/helm-sendbox/values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-registry ${PROJECT_ROOT}/mock/mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-cds ${PROJECT_ROOT}/mock/mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bap ${PROJECT_ROOT}/mock/mock-bap \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bpp ${PROJECT_ROOT}/mock/mock-bpp \
  --namespace ev-charging-sandbox
```

**📋 Step-by-Step Deployment**

**IMPORTANT**: Run these commands from the `helm-sendbox` directory.

```bash
# Navigate to the correct directory
cd helm-sendbox

# 1. Create namespace
kubectl create namespace ev-charging-sandbox

# 2. Deploy BAP adapter
helm upgrade --install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# 3. Deploy BPP adapter
helm upgrade --install onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox

# 4. Deploy Mock Registry
helm upgrade --install mock-registry ../../../mock-registry \
  --namespace ev-charging-sandbox

# 5. Deploy Mock CDS
helm upgrade --install mock-cds ../../../mock-cds \
  --namespace ev-charging-sandbox

# 6. Deploy Mock BAP
helm upgrade --install mock-bap ../../../mock-bap \
  --namespace ev-charging-sandbox

# 7. Deploy Mock BPP
helm upgrade --install mock-bpp ../../../mock-bpp \
  --namespace ev-charging-sandbox

# 8. Verify all services are running
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox
```

**Troubleshooting Path Issues**

If you get "path not found" errors:

1. **Verify you're in the correct directory**:
   ```bash
   pwd
   # Should end with: .../ubc-ev-sandbox/helm-sendbox
   ```

2. **Check the paths exist**:
   ```bash
   ls -d ../helm
   ls -d ../mock/mock-registry
   ```

3. **Use absolute paths** (see Alternative method above)

4. **Or navigate from project root**:
   ```bash
   # From project root
   cd helm-sendbox
   # Then run the helm commands
   ```

**✅ Verify All Services Are Running**

```bash
# Check all pods are ready
kubectl get pods -n ev-charging-sandbox

# Expected output should show:
# - onix-bap-* (BAP adapter)
# - onix-bpp-* (BPP adapter)
# - mock-registry-* (Registry service)
# - mock-cds-* (CDS service)
# - mock-bap-* (Mock BAP backend)
# - mock-bpp-* (Mock BPP backend)
# - redis-* (Redis instances)

# Check all services
kubectl get svc -n ev-charging-sandbox

# Check pod logs if any are not ready
kubectl logs -n ev-charging-sandbox <pod-name>
```

**🔌 Port Forward All Services (Optional)**

If services are ClusterIP type, use port forwarding to access them locally:

```bash
# Use the provided port-forward script
./port-forward.sh

# Or manually port forward each service:
kubectl port-forward -n ev-charging-sandbox svc/onix-bap-service 8001:8001 &
kubectl port-forward -n ev-charging-sandbox svc/onix-bpp-service 8002:8002 &
kubectl port-forward -n ev-charging-sandbox svc/mock-registry 3030:3030 &
kubectl port-forward -n ev-charging-sandbox svc/mock-cds 8082:8082 &
kubectl port-forward -n ev-charging-sandbox svc/mock-bap 9001:9001 &
kubectl port-forward -n ev-charging-sandbox svc/mock-bpp 9002:9002 &
```

**🧪 Test the Deployment**

Once all services are running, test with the provided test messages:

```bash
# Test BAP endpoints
cd message/bap/test
./test-all.sh discover

# Test BPP endpoints
cd ../bpp/test
./test-on-discover.sh
```

See the [Testing with Sample Messages](#testing-with-sample-messages) section for more details.

### Deploy BAP Component

```bash
# Navigate to this directory
cd helm-sendbox

# Deploy BAP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install onix-bap-1 ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install onix-bap-2 ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods -l component=bap
kubectl get pods -n ev-charging-sandbox -l component=bap  # If using namespace
kubectl get svc -n ev-charging-sandbox -l component=bap
```

### Deploy BPP Component

```bash
# Deploy BPP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --set fullnameOverride=onix-bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Check deployment status
kubectl get pods -l component=bpp
kubectl get pods -n ev-charging-sandbox -l component=bpp  # If using namespace
kubectl get svc -n ev-charging-sandbox -l component=bpp
```

### Using Namespaces

You can deploy to a specific namespace using the `--namespace` flag. The `--create-namespace` flag will create the namespace if it doesn't exist:

```bash
# Create namespace first (optional)
kubectl create namespace ev-charging-sandbox

# Deploy with namespace (idempotent - installs or upgrades)
helm upgrade --install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
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

### Mock Services Deployment

Mock services (mock-registry, mock-cds, mock-bap, mock-bpp) are configured in `values-sandbox.yaml` under the `mockServices` section. This configuration includes image repositories, ports, config file paths, and health check settings for each service.

**Configuration Location**: All mock service configurations are defined in `helm-sendbox/values-sandbox.yaml` under the `mockServices` section. See the [Configuration Files](#configuration-files) section for details.

**Deployment Options**: Mock services can be deployed using:
1. **Helm Charts** (available in `mock/mock-*` directories)
2. **Docker Compose** (from the `sandbox/` directory)

#### Deploy All Mock Services with Helm (Recommended)

**Note**: The mock service configurations (images, ports, config paths) are defined in `values-sandbox.yaml`. If Helm charts exist for mock services, deploy them as shown below:

```bash
# Navigate to sandbox directory
cd ../../..

# Deploy mock-registry
helm upgrade --install mock-registry ./mock/mock-registry \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy mock-cds
helm upgrade --install mock-cds ./mock/mock-cds \
  --namespace ev-charging-sandbox

# Deploy mock-bap
helm upgrade --install mock-bap ./mock/mock-bap \
  --namespace ev-charging-sandbox

# Deploy mock-bpp
helm upgrade --install mock-bpp ./mock/mock-bpp \
  --namespace ev-charging-sandbox

# Or deploy all at once
helm upgrade --install mock-registry ./mock/mock-registry \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install mock-cds ./mock/mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bap ./mock/mock-bap \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bpp ./mock/mock-bpp \
  --namespace ev-charging-sandbox

# Verify all mock services are running
kubectl get pods -n ev-charging-sandbox | grep mock
kubectl get svc -n ev-charging-sandbox | grep mock
```

#### Alternative: Deploy Mock Services via Docker Compose

If you're running Kubernetes locally (e.g., minikube, kind) and prefer Docker Compose:

```bash
# From the sandbox root directory
cd ../../docker/api/monolithic

# Deploy all mock services
docker-compose up -d mock-registry mock-cds mock-bap mock-bpp

# Verify services are running
docker-compose ps
```

**Note**: 
- Mock service configurations (images, ports, config paths, health checks) are defined in `values-sandbox.yaml` under the `mockServices` section
- If Helm charts are available, each mock service Helm chart includes:
  - Deployment with health probes (configured via `mockServices.*.healthcheck`)
  - Service with ClusterIP (configured via `mockServices.*.service`)
  - ConfigMap with service configuration (from `mockServices.*.config.path`)
  - Resource limits and requests
- If Helm charts are not available, use docker-compose from the `sandbox/` directory (see below)

### Installing Multiple Instances

If you need multiple instances of the same component in the same namespace, use different release names:

```bash
# Install first BAP instance
helm install onix-bap-1 ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install second BAP instance with different name
helm install onix-bap-2 ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Each instance will have different service names and can run on different ports
```

## Services Deployed

When you deploy the complete sandbox environment, the following services are created:

### ONIX Adapters

1. **onix-bap-service** (Port: 8001)
   - ONIX protocol adapter for BAP (Buyer App Provider)
   - Handles protocol compliance, signing, validation, and routing for BAP transactions
   - **Caller Endpoint**: `/bap/caller/{action}` - Entry point for requests from BAP application
   - **Receiver Endpoint**: `/bap/receiver/{action}` - Receives callbacks from CDS and BPPs

2. **onix-bpp-service** (Port: 8002)
   - ONIX protocol adapter for BPP (Buyer Platform Provider)
   - Handles protocol compliance, signing, validation, and routing for BPP transactions
   - **Caller Endpoint**: `/bpp/caller/{action}` - Sends responses to CDS and BAPs
   - **Receiver Endpoint**: `/bpp/receiver/{action}` - Receives requests from CDS and BAPs

### Mock Services

3. **mock-registry** (Port: 3030)
   - Mock implementation of the network registry service
   - Maintains a registry of all BAPs, BPPs, and CDS services on the network
   - Provides subscriber lookup and key management functionality
   - Service name matches sandbox/ docker-compose setup

4. **mock-cds** (Port: 8082)
   - Mock Catalog Discovery Service (CDS)
   - Aggregates discover requests from BAPs and broadcasts to registered BPPs
   - Collects and aggregates responses from multiple BPPs
   - Handles signature verification and signing
   - Service name matches sandbox/ docker-compose setup

5. **mock-bap** (Port: 9001)
   - Single mock BAP backend service handling all endpoints
   - Simulates a Buyer App Provider application
   - Receives all callbacks from the ONIX adapter (on_discover, on_select, on_init, etc.)
   - Service name matches sandbox/ docker-compose setup

6. **mock-bpp** (Port: 9002)
   - Single mock BPP backend service handling all endpoints
   - Simulates a Buyer Platform Provider application
   - Handles all requests from the ONIX adapter (discover, select, init, confirm, etc.)
   - Service name matches sandbox/ docker-compose setup

### Supporting Services

7. **onix-bap-redis-bap** (Port: 6379)
   - Redis cache for the BAP adapter
   - Used for storing transaction state, caching registry lookups, and session management
   - Service name uses fullnameOverride pattern for consistency

8. **onix-bpp-redis-bpp** (Port: 6379)
   - Redis cache for the BPP adapter
   - Used for storing transaction state, caching registry lookups, and session management
   - Service name uses fullnameOverride pattern for consistency


## Configuration Files

### `values-sandbox.yaml`

This file contains sandbox-specific overrides for the Helm chart. It includes:

- **Service Configuration**: Exposes BAP and BPP ONIX plugins externally (LoadBalancer/NodePort)
- **Secret Management**: Optional configuration for production secret management
- **Mock Services Configuration**: Complete configuration for all mock services (registry, CDS, BAP, BPP)

**Key Features**:
- Uses simplified resource names (`onix-bap`, `onix-bpp`) via `fullnameOverride`
- Includes comprehensive mock service configurations with image, ports, config paths, and health checks
- Pre-configured routing for monolithic architecture (single service per role)
- **Service Exposure**: BAP and BPP ONIX plugins are exposed externally (LoadBalancer), while mock services remain internal (ClusterIP)

#### Mock Services Configuration

The `mockServices` section in `values-sandbox.yaml` defines configurations for all mock services:

**Full Configuration Structure**:

```yaml
mockServices:
  enabled: true  # Master switch: set to false to skip all mock service deployment
  mockRegistry:
    enabled: true  # Enable/disable this specific service
    image:
      repository: manendrapalsingh/mock-registry
      tag: latest
    service:
      type: ClusterIP
      port: 3030
    config:
      path: ../sandbox/mock-registry_config.yml
    healthcheck:
      enabled: true
      path: /health
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
  mockCds:
    enabled: true
    image:
      repository: manendrapalsingh/mock-cds
      tag: latest
    service:
      type: ClusterIP
      port: 8082
    config:
      path: ../sandbox/mock-cds_config.yml
    healthcheck:
      enabled: true
      path: /health
      initialDelaySeconds: 30
      periodSeconds: 30
      timeoutSeconds: 10
      failureThreshold: 3
  mockBap:
    enabled: true
    image:
      repository: manendrapalsingh/mock-bap
      tag: latest
    service:
      type: ClusterIP
      port: 9001
    config:
      path: ../sandbox/mock-bap_config.yml
    healthcheck:
      enabled: true
      path: /health
      initialDelaySeconds: 30
      periodSeconds: 30
      timeoutSeconds: 10
      failureThreshold: 3
  mockBpp:
    enabled: true
    image:
      repository: manendrapalsingh/mock-bpp
      tag: latest
    service:
      type: ClusterIP
      port: 9002
    config:
      path: ../sandbox/mock-bpp_config.yml
      requestJsonPath: ../sandbox/request.json
    healthcheck:
      enabled: true
      path: /health
      initialDelaySeconds: 30
      periodSeconds: 30
      timeoutSeconds: 10
      failureThreshold: 3
```

**Configuration Options**:

| Option | Description | Example |
|--------|-------------|---------|
| `mockServices.enabled` | Master switch to enable/disable all mock services | `true` or `false` |
| `mockServices.<service>.enabled` | Enable/disable individual mock service | `mockRegistry.enabled: true` |
| `image.repository` | Docker image repository | `manendrapalsingh/mock-registry` |
| `image.tag` | Docker image tag | `latest` |
| `service.type` | Kubernetes service type | `ClusterIP`, `NodePort`, `LoadBalancer` |
| `service.port` | Service port number | `3030`, `8082`, `9001`, `9002` |
| `config.path` | Path to service config file (relative to `helm-sendbox/`) | `../sandbox/mock-registry_config.yml` |
| `config.requestJsonPath` | Path to request.json (for mock-bpp only) | `../sandbox/request.json` |
| `healthcheck.enabled` | Enable Kubernetes health probes | `true` or `false` |
| `healthcheck.path` | Health check endpoint path | `/health` |
| `healthcheck.initialDelaySeconds` | Initial delay before first probe | `10`, `30` |
| `healthcheck.periodSeconds` | Probe interval | `10`, `30` |
| `healthcheck.timeoutSeconds` | Probe timeout | `5`, `10` |
| `healthcheck.failureThreshold` | Consecutive failures before marking unhealthy | `3` |

**Usage Examples**:

**Disable All Mock Services**:
```yaml
mockServices:
  enabled: false
```

**Disable Specific Service**:
```yaml
mockServices:
  enabled: true
  mockRegistry:
    enabled: false  # Only mock-registry is disabled
```

**Change Service Port**:
```yaml
mockServices:
  mockRegistry:
    service:
      port: 3031  # Change from default 3030 to 3031
```

**Use Different Image Tag**:
```yaml
mockServices:
  mockRegistry:
    image:
      tag: v1.0.0  # Use specific version instead of latest
```

**Deployment Notes**:
- Config file paths are relative to the `helm-sendbox` directory
- Mock services can be deployed using Helm charts from the `mock/mock-*` directories
- The configuration in `values-sandbox.yaml` serves as the source of truth for mock service settings
- When deploying via Helm charts, these values can be used to generate the deployment manifests
- When deploying via docker-compose, these values should match the docker-compose.yml configuration

## Service Endpoints

### Service Exposure Configuration

**External Services (Exposed Outside Cluster):**
- **BAP ONIX Plugin** - Exposed via LoadBalancer/NodePort (port 8001)
- **BPP ONIX Plugin** - Exposed via LoadBalancer/NodePort (port 8002)

**Internal Services (ClusterIP Only):**
- **Mock Registry** - ClusterIP (port 3030) - Internal only
- **Mock CDS** - ClusterIP (port 8082) - Internal only
- **Mock BAP** - ClusterIP (port 9001) - Internal only
- **Mock BPP** - ClusterIP (port 9002) - Internal only
- **Redis** - ClusterIP (port 6379/6380) - Internal only

This configuration ensures that:
- BAP and BPP ONIX plugins are accessible from outside the cluster for API testing
- All mock services and Redis remain secure within the cluster
- Inter-service communication uses Kubernetes internal DNS

### Service Details

Once all services are deployed, you can access them via Kubernetes services:

| Service | Service Name | Port | Type | Access |
|---------|--------------|------|------|--------|
| **ONIX BAP** | `onix-bap-service` | 8001 | LoadBalancer | External: `http://<external-ip>:8001`<br>Internal: `http://onix-bap-service:8001` |
| | `/bap/caller/{action}` | | | Send requests from BAP |
| | `/bap/receiver/{action}` | | | Receive callbacks |
| **ONIX BPP** | `onix-bpp-service` | 8002 | LoadBalancer | External: `http://<external-ip>:8002`<br>Internal: `http://onix-bpp-service:8002` |
| | `/bpp/caller/{action}` | | | Send responses |
| | `/bpp/receiver/{action}` | | | Receive requests |
| **Mock Registry** | `mock-registry` | 3030 | ClusterIP | Internal only: `http://mock-registry:3030` |
| **Mock CDS** | `mock-cds` | 8082 | ClusterIP | Internal only: `http://mock-cds:8082` |
| **Mock BAP** | `mock-bap` | 9001 | ClusterIP | Internal only: `http://mock-bap:9001` |
| **Mock BPP** | `mock-bpp` | 9002 | ClusterIP | Internal only: `http://mock-bpp:9002` |
| **Redis BAP** | `onix-bap-redis-bap` | 6379 | ClusterIP | Internal only: `onix-bap-redis-bap:6379` |
| **Redis BPP** | `onix-bpp-redis-bpp` | 6379 | ClusterIP | Internal only: `onix-bpp-redis-bpp:6379` |

### Getting External IP Addresses

After deployment, get the external IP addresses for BAP and BPP:

```bash
# Get external IP for BAP service
kubectl get svc -n ev-charging-sandbox onix-bap-service

# Get external IP for BPP service
kubectl get svc -n ev-charging-sandbox onix-bpp-service

# Or get both at once
kubectl get svc -n ev-charging-sandbox -l 'component in (bap,bpp)'

# For NodePort type, get the node IP and port
kubectl get nodes -o wide  # Get node IP
kubectl get svc -n ev-charging-sandbox onix-bap-service -o jsonpath='{.spec.ports[0].nodePort}'
```

## Accessing Services

### External Access (LoadBalancer/NodePort)

Since BAP and BPP services are exposed externally via LoadBalancer, you can access them directly without port forwarding:

```bash
# Get external IP addresses
kubectl get svc -n ev-charging-sandbox onix-bap-service
kubectl get svc -n ev-charging-sandbox onix-bpp-service

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
kubectl port-forward -n ev-charging-sandbox svc/onix-bap-service 8001:8001

# Port forward BPP adapter (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/onix-bpp-service 8002:8002

# Port forward Mock Registry (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/mock-registry 3030:3030

# Port forward Mock CDS (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/mock-cds 8082:8082

# Port forward Mock BAP (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/mock-bap 9001:9001

# Port forward Mock BPP (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/mock-bpp 9002:9002
```

**Or use the provided port-forward script:**

```bash
# Run the port-forward script (manages all port forwards)
./port-forward.sh

# Or run all port forwards manually in background
kubectl port-forward -n ev-charging-sandbox svc/onix-bap-service 8001:8001 &
kubectl port-forward -n ev-charging-sandbox svc/onix-bpp-service 8002:8002 &
kubectl port-forward -n ev-charging-sandbox svc/mock-registry 3030:3030 &
kubectl port-forward -n ev-charging-sandbox svc/mock-cds 8082:8082 &
kubectl port-forward -n ev-charging-sandbox svc/mock-bap 9001:9001 &
kubectl port-forward -n ev-charging-sandbox svc/mock-bpp 9002:9002 &

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
   kubectl get svc -n ev-charging-sandbox onix-bap-service
   # Use the EXTERNAL-IP in Postman environment variables
   ```
   
   **Option B: Port forwarding (if LoadBalancer not available):**
   ```bash
   # For BAP endpoints
   kubectl port-forward -n ev-charging-sandbox svc/onix-bap-service 8001:8001
   
   # For BPP endpoints (in another terminal)
   kubectl port-forward -n ev-charging-sandbox svc/onix-bpp-service 8002:8002
   ```

3. Select the imported environment in Postman and start making API calls.

**Example API Calls (after port forwarding):**

```bash
# Test BAP health endpoint
curl http://localhost:8001/health

# Test BAP confirm endpoint
curl -X POST http://localhost:8001/bap/caller/confirm \
  -H "Content-Type: application/json" \
  -d '{"context": {...}, "message": {...}}'

# Test BPP health endpoint
curl http://localhost:8002/health
```

### Using Ingress (if configured)

If you have an Ingress controller configured, you can access services via Ingress routes instead of port forwarding.

## Updating Configuration

### Update Values

```bash
# Update BAP deployment (or use upgrade --install for idempotent updates)
helm upgrade onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Update BPP deployment (or use upgrade --install for idempotent updates)
helm upgrade onix-bpp ../helm \
  -f ../helm/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox

# Alternative: Use upgrade --install for idempotent operations (installs if not exists, upgrades if exists)
helm upgrade --install onix-bap ../helm \
  -f ../helm/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --set fullnameOverride=onix-bap \
  --namespace ev-charging-sandbox \
  --create-namespace
```

### Modify Routing

Edit `values-sandbox.yaml` and update the `config.routing` sections, then upgrade the Helm release.

## Troubleshooting

### Check Pod Status

```bash
# Check all pods
kubectl get pods

# Check specific component
kubectl get pods -n ev-charging-sandbox -l component=bap
kubectl get pods -n ev-charging-sandbox -l component=bpp

# Check pod logs
kubectl logs -n ev-charging-sandbox <pod-name>
kubectl logs -f -n ev-charging-sandbox <pod-name>  # Follow logs
kubectl logs -n ev-charging-sandbox -l component=bap  # Logs for all BAP pods
kubectl logs -n ev-charging-sandbox -l component=bpp  # Logs for all BPP pods
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
kubectl get configmap onix-bap-adapter -n ev-charging-sandbox -o jsonpath='{.data.adapter\.yaml}'
kubectl get configmap onix-bpp-adapter -n ev-charging-sandbox -o jsonpath='{.data.adapter\.yaml}'
```

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Service not accessible**: Verify service selectors match pod labels
3. **Configuration errors**: Check ConfigMap content and pod logs
4. **Network issues**: Verify service names are correct in configuration

## Uninstalling

### Quick Uninstall (All Services)

To remove the complete sandbox environment in one command:

```bash
# Uninstall all Helm releases at once
helm uninstall onix-bap onix-bpp mock-registry mock-cds mock-bap mock-bpp \
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
helm uninstall mock-bap --namespace ev-charging-sandbox
helm uninstall mock-bpp --namespace ev-charging-sandbox

# 3. Clean up remaining resources (if not deleting namespace)
kubectl delete configmap -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic
kubectl delete pvc -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic

# 4. Remove namespace (optional - removes everything in namespace)
kubectl delete namespace ev-charging-sandbox
```

### Uninstall Individual Services

To remove specific services:

```bash
# Uninstall BAP adapter
helm uninstall onix-bap --namespace ev-charging-sandbox

# Uninstall BPP adapter
helm uninstall onix-bpp --namespace ev-charging-sandbox

# Uninstall individual mock services
helm uninstall mock-registry --namespace ev-charging-sandbox
helm uninstall mock-cds --namespace ev-charging-sandbox
helm uninstall mock-bap --namespace ev-charging-sandbox
helm uninstall mock-bpp --namespace ev-charging-sandbox
```

### Uninstall Mock Services (if deployed via Docker Compose)

If mock services were deployed using docker-compose instead of Helm:

```bash
# Navigate to sandbox directory
cd ../sandbox

# Stop and remove mock services
docker-compose down mock-registry mock-cds mock-bap mock-bpp

# Or stop all services
docker-compose down
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

# Verify all PVCs are removed
kubectl get pvc -n ev-charging-sandbox
```

### Complete Cleanup

To completely remove everything including the namespace:

```bash
# Uninstall all Helm releases
helm uninstall onix-bap onix-bpp mock-registry mock-cds mock-bap mock-bpp \
  --namespace ev-charging-sandbox

# Delete the entire namespace (removes all resources)
kubectl delete namespace ev-charging-sandbox

# Verify namespace is deleted
kubectl get namespace ev-charging-sandbox
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Main Helm Chart README](../helm/README.md) - Detailed Helm chart documentation
- [Docker Sandbox README](../sandbox/README.md) - Docker Compose equivalent setup

## Notes

- Service names in Kubernetes use DNS resolution within the cluster
- All services communicate using Kubernetes service names (e.g., `mock-registry:3030`, `mock-cds:8082`, `mock-bap:9001`, `mock-bpp:9002`)
- Configuration is managed through Helm values files and ConfigMaps
- **Monolithic Architecture**: Single service handles all endpoints:
  - `mock-bap` handles all BAP callbacks (on_discover, on_select, on_init, etc.)
  - `mock-bpp` handles all BPP requests (discover, select, init, confirm, etc.)
- Mock services are configured in `values-sandbox.yaml` under the `mockServices` section, which includes image, port, config path, and health check settings
- Mock services can be deployed using Helm charts (if available) or docker-compose from the `sandbox/` directory
- Use `mockServices.enabled: false` to skip mock service deployment, or disable individual services using `mockServices.<service>.enabled: false`
- Production deployments should use proper secrets management for keys and credentials
- Service names match the sandbox/ docker-compose setup for consistency

