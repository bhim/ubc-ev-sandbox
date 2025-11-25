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
cd sandbox/helm/api/monolithic
./deploy-all.sh
```

The script automatically:
- Verifies all paths exist
- Creates the namespace if needed
- Deploys all services (BAP, BPP, and mock services)
- Populates schemas
- Shows deployment status

**Option 2: Manual Deployment**

**IMPORTANT**: You must run these commands from the `sandbox/helm/api/monolithic` directory.

```bash
# Navigate to sandbox directory (from project root)
cd sandbox/helm/api/monolithic

# Verify you're in the right directory (should see values-sandbox.yaml)
pwd
# Should output: .../ev_charging_sandbox/sandbox/helm/api/monolithic
ls values-sandbox.yaml

# Deploy all services (BAP, BPP, and mock services)
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-registry ../../../mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-cds ../../../mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bap ../../../mock-bap \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bpp ../../../mock-bpp \
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
helm upgrade --install ev-charging-bap ${PROJECT_ROOT}/helm/api/monolithic \
  -f ${PROJECT_ROOT}/helm/api/monolithic/values-bap.yaml \
  -f ${PROJECT_ROOT}/sandbox/helm/api/monolithic/values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install ev-charging-bpp ${PROJECT_ROOT}/helm/api/monolithic \
  -f ${PROJECT_ROOT}/helm/api/monolithic/values-bpp.yaml \
  -f ${PROJECT_ROOT}/sandbox/helm/api/monolithic/values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-registry ${PROJECT_ROOT}/sandbox/mock-registry \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-cds ${PROJECT_ROOT}/sandbox/mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bap ${PROJECT_ROOT}/sandbox/mock-bap \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bpp ${PROJECT_ROOT}/sandbox/mock-bpp \
  --namespace ev-charging-sandbox
```

**📋 Step-by-Step Deployment**

**IMPORTANT**: Run these commands from the `sandbox/helm/api/monolithic` directory.

```bash
# Navigate to the correct directory
cd sandbox/helm/api/monolithic

# 1. Create namespace
kubectl create namespace ev-charging-sandbox

# 2. Deploy BAP adapter
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# 3. Deploy BPP adapter
helm upgrade --install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
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

# 8. Populate schemas
./populate-schemas.sh

# 9. Verify all services are running
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox
```

**Troubleshooting Path Issues**

If you get "path not found" errors:

1. **Verify you're in the correct directory**:
   ```bash
   pwd
   # Should end with: .../ev_charging_sandbox/sandbox/helm/api/monolithic
   ```

2. **Check the paths exist**:
   ```bash
   ls -d ../../../../helm/api/monolithic
   ls -d ../../../mock-registry
   ```

3. **Use absolute paths** (see Alternative method above)

4. **Or navigate from project root**:
   ```bash
   # From project root
   cd sandbox/helm/api/monolithic
   # Then run the helm commands
   ```

**✅ Verify All Services Are Running**

```bash
# Check all pods are ready
kubectl get pods -n ev-charging-sandbox

# Expected output should show:
# - ev-charging-bap-* (BAP adapter)
# - ev-charging-bpp-* (BPP adapter)
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
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-monolithic-bap-service 8001:8001 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-monolithic-bpp-service 8002:8002 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-registry 3030:3030 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-cds 8082:8082 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap 9001:9001 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp 9002:9002 &
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
cd sandbox/helm/api/monolithic

# Deploy BAP with sandbox configuration (default namespace)
# Option 1: Install (will fail if release already exists)
helm install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-bap-1 ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-bap-2 ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
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
helm install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Deploy to a specific namespace
# Option 1: Install (will fail if release already exists)
helm install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Option 2: Upgrade or Install (idempotent - recommended)
helm upgrade --install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
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
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
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

Mock services (mock-registry, mock-cds, mock-bap, mock-bpp) can be deployed using their individual Helm charts. Each mock service has its own Helm chart in the `sandbox/` directory.

#### Deploy All Mock Services with Helm (Recommended)

```bash
# Navigate to sandbox directory
cd ../../..

# Deploy mock-registry
helm upgrade --install mock-registry ./sandbox/mock-registry \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy mock-cds
helm upgrade --install mock-cds ./sandbox/mock-cds \
  --namespace ev-charging-sandbox

# Deploy mock-bap
helm upgrade --install mock-bap ./sandbox/mock-bap \
  --namespace ev-charging-sandbox

# Deploy mock-bpp
helm upgrade --install mock-bpp ./sandbox/mock-bpp \
  --namespace ev-charging-sandbox

# Or deploy all at once
helm upgrade --install mock-registry ./sandbox/mock-registry \
  --namespace ev-charging-sandbox \
  --create-namespace && \
helm upgrade --install mock-cds ./sandbox/mock-cds \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bap ./sandbox/mock-bap \
  --namespace ev-charging-sandbox && \
helm upgrade --install mock-bpp ./sandbox/mock-bpp \
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

**Note**: Each mock service Helm chart includes:
- Deployment with health probes
- Service with ClusterIP (configurable)
- ConfigMap with service configuration
- Resource limits and requests

### Installing Multiple Instances

If you need multiple instances of the same component in the same namespace, use different release names:

```bash
# Install first BAP instance
helm install ev-charging-bap-1 ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install second BAP instance with different name
helm install ev-charging-bap-2 ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Each instance will have different service names and can run on different ports
```

## Services Deployed

When you deploy the complete sandbox environment, the following services are created:

### ONIX Adapters

1. **ev-charging-bap-onix-api-monolithic-bap-service** (Port: 8001)
   - ONIX protocol adapter for BAP (Buyer App Provider)
   - Handles protocol compliance, signing, validation, and routing for BAP transactions
   - **Caller Endpoint**: `/bap/caller/{action}` - Entry point for requests from BAP application
   - **Receiver Endpoint**: `/bap/receiver/{action}` - Receives callbacks from CDS and BPPs

2. **ev-charging-bpp-onix-api-monolithic-bpp-service** (Port: 8002)
   - ONIX protocol adapter for BPP (Buyer Platform Provider)
   - Handles protocol compliance, signing, validation, and routing for BPP transactions
   - **Caller Endpoint**: `/bpp/caller/{action}` - Sends responses to CDS and BAPs
   - **Receiver Endpoint**: `/bpp/receiver/{action}` - Receives requests from CDS and BAPs

### Mock Services

3. **ev-charging-mock-registry** (Port: 3030)
   - Mock implementation of the network registry service
   - Maintains a registry of all BAPs, BPPs, and CDS services on the network
   - Provides subscriber lookup and key management functionality

4. **ev-charging-mock-cds** (Port: 8082)
   - Mock Catalog Discovery Service (CDS)
   - Aggregates discover requests from BAPs and broadcasts to registered BPPs
   - Collects and aggregates responses from multiple BPPs
   - Handles signature verification and signing

5. **ev-charging-mock-bap** (Port: 9001)
   - Single mock BAP backend service handling all endpoints
   - Simulates a Buyer App Provider application
   - Receives all callbacks from the ONIX adapter (on_discover, on_select, on_init, etc.)

6. **ev-charging-mock-bpp** (Port: 9002)
   - Single mock BPP backend service handling all endpoints
   - Simulates a Buyer Platform Provider application
   - Handles all requests from the ONIX adapter (discover, select, init, confirm, etc.)

### Supporting Services

7. **ev-charging-redis-onix-bap** (Port: 6379)
   - Redis cache for the BAP adapter
   - Used for storing transaction state, caching registry lookups, and session management

8. **ev-charging-redis-onix-bpp** (Port: 6380)
   - Redis cache for the BPP adapter
   - Used for storing transaction state, caching registry lookups, and session management


## Configuration Files

### `values-sandbox.yaml`

This file contains sandbox-specific overrides for the Helm chart. It includes:

- Mock services configuration (registry, CDS, BAP, BPP)
- Adapter configuration with Kubernetes service names
- Routing configuration for monolithic architecture

**Key Features**:
- Uses Kubernetes service names instead of container names
- Includes all mock service configurations
- Pre-configured routing for monolithic architecture (single service per role)
- **Service Exposure**: BAP and BPP ONIX plugins are exposed externally (LoadBalancer), while mock services remain internal (ClusterIP)

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
| **ONIX BAP** | `ev-charging-bap-onix-api-monolithic-bap-service` | 8001 | LoadBalancer | External: `http://<external-ip>:8001`<br>Internal: `http://ev-charging-bap-onix-api-monolithic-bap-service:8001` |
| | `/bap/caller/{action}` | | | Send requests from BAP |
| | `/bap/receiver/{action}` | | | Receive callbacks |
| **ONIX BPP** | `ev-charging-bpp-onix-api-monolithic-bpp-service` | 8002 | LoadBalancer | External: `http://<external-ip>:8002`<br>Internal: `http://ev-charging-bpp-onix-api-monolithic-bpp-service:8002` |
| | `/bpp/caller/{action}` | | | Send responses |
| | `/bpp/receiver/{action}` | | | Receive requests |
| **Mock Registry** | `ev-charging-mock-registry` | 3030 | ClusterIP | Internal only: `http://ev-charging-mock-registry:3030` |
| **Mock CDS** | `ev-charging-mock-cds` | 8082 | ClusterIP | Internal only: `http://ev-charging-mock-cds:8082` |
| **Mock BAP** | `ev-charging-mock-bap` | 9001 | ClusterIP | Internal only: `http://ev-charging-mock-bap:9001` |
| **Mock BPP** | `ev-charging-mock-bpp` | 9002 | ClusterIP | Internal only: `http://ev-charging-mock-bpp:9002` |
| **Redis BAP** | `ev-charging-redis-onix-bap` | 6379 | ClusterIP | Internal only: `ev-charging-redis-onix-bap:6379` |
| **Redis BPP** | `ev-charging-redis-onix-bpp` | 6379 | ClusterIP | Internal only: `ev-charging-redis-onix-bpp:6379` |

### Getting External IP Addresses

After deployment, get the external IP addresses for BAP and BPP:

```bash
# Get external IP for BAP service
kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-monolithic-bap-service

# Get external IP for BPP service
kubectl get svc -n ev-charging-sandbox ev-charging-bpp-onix-api-monolithic-bpp-service

# Or get both at once
kubectl get svc -n ev-charging-sandbox -l 'component in (bap,bpp)'

# For NodePort type, get the node IP and port
kubectl get nodes -o wide  # Get node IP
kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-monolithic-bap-service -o jsonpath='{.spec.ports[0].nodePort}'
```

## Accessing Services

### External Access (LoadBalancer/NodePort)

Since BAP and BPP services are exposed externally via LoadBalancer, you can access them directly without port forwarding:

```bash
# Get external IP addresses
kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-monolithic-bap-service
kubectl get svc -n ev-charging-sandbox ev-charging-bpp-onix-api-monolithic-bpp-service

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
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-monolithic-bap-service 8001:8001

# Port forward BPP adapter (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-monolithic-bpp-service 8002:8002

# Port forward Mock Registry (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-registry 3030:3030

# Port forward Mock CDS (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-cds 8082:8082

# Port forward Mock BAP (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap 9001:9001

# Port forward Mock BPP (run in a separate terminal)
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp 9002:9002
```

**Or use the provided port-forward script:**

```bash
# Run the port-forward script (manages all port forwards)
./port-forward.sh

# Or run all port forwards manually in background
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-monolithic-bap-service 8001:8001 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-monolithic-bpp-service 8002:8002 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-registry 3030:3030 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-cds 8082:8082 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bap 9001:9001 &
kubectl port-forward -n ev-charging-sandbox svc/ev-charging-mock-bpp 9002:9002 &

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
   kubectl get svc -n ev-charging-sandbox ev-charging-bap-onix-api-monolithic-bap-service
   # Use the EXTERNAL-IP in Postman environment variables
   ```
   
   **Option B: Port forwarding (if LoadBalancer not available):**
   ```bash
   # For BAP endpoints
   kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bap-onix-api-monolithic-bap-service 8001:8001
   
   # For BPP endpoints (in another terminal)
   kubectl port-forward -n ev-charging-sandbox svc/ev-charging-bpp-onix-api-monolithic-bpp-service 8002:8002
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

## Schema Configuration

The ONIX adapters require JSON schemas for validation. Schemas are automatically populated from the `schemas/beckn.one_deg_ev-charging/v2.0.0/` directory into Kubernetes ConfigMaps.

### Populating Schemas

Schemas are automatically copied into pods via an initContainer. However, you need to populate the ConfigMaps first:

**Option 1: Using the helper script (Recommended)**

```bash
# From sandbox/helm/api/monolithic directory
./populate-schemas.sh

# Or specify custom namespace
NAMESPACE=my-namespace ./populate-schemas.sh
```

**Option 2: Manual ConfigMap creation**

```bash
# Create schemas ConfigMap for BAP
kubectl create configmap ev-charging-bap-onix-api-monolithic-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Create schemas ConfigMap for BPP
kubectl create configmap ev-charging-bpp-onix-api-monolithic-schemas \
  --from-file=../../../../schemas/beckn.one_deg_ev-charging/v2.0.0/ \
  -n ev-charging-sandbox \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new schemas
kubectl delete pod -n ev-charging-sandbox -l component=bap
kubectl delete pod -n ev-charging-sandbox -l component=bpp
```

### Verifying Schemas

After deployment, verify schemas are correctly mounted:

```bash
# Check if schemas are present in BAP pod
kubectl exec -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=bap -o jsonpath='{.items[0].metadata.name}') \
  -- ls -la /app/schemas/beckn.one_deg_ev-charging/v2.0.0/

# Check initContainer logs
kubectl logs -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=bap -o jsonpath='{.items[0].metadata.name}') \
  -c schema-setup
```

### Updating Schemas

When schema files are updated:

1. Update the ConfigMap:
   ```bash
   ./populate-schemas.sh
   ```

2. Restart the pods:
   ```bash
   kubectl delete pod -n ev-charging-sandbox -l component=bap
   kubectl delete pod -n ev-charging-sandbox -l component=bpp
   ```

### Schema Validation Errors

If you encounter errors like `schema validation failed: schema not found for domain: beckn.one_deg_ev-charging`:

1. **Verify ConfigMap exists:**
   ```bash
   kubectl get configmap -n ev-charging-sandbox | grep schemas
   ```

2. **Check ConfigMap contents:**
   ```bash
   kubectl get configmap ev-charging-bap-onix-api-monolithic-schemas \
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
     $(kubectl get pod -n ev-charging-sandbox -l component=bap -o jsonpath='{.items[0].metadata.name}') \
     -c bap-plugin | grep -i schema
   ```

For more details, see [Schema Setup Guide](../../SCHEMA_SETUP.md).

## Updating Configuration

### Update Values

```bash
# Update BAP deployment (or use upgrade --install for idempotent updates)
helm upgrade ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Update BPP deployment (or use upgrade --install for idempotent updates)
helm upgrade ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox

# Alternative: Use upgrade --install for idempotent operations (installs if not exists, upgrades if exists)
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
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
kubectl get configmap ev-charging-bap-onix-api-monolithic-bap-adapter -n ev-charging-sandbox -o jsonpath='{.data.adapter\.yaml}'
kubectl get configmap ev-charging-bpp-onix-api-monolithic-bpp-adapter -n ev-charging-sandbox -o jsonpath='{.data.adapter\.yaml}'
```

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Service not accessible**: Verify service selectors match pod labels
3. **Configuration errors**: Check ConfigMap content and pod logs
4. **Network issues**: Verify service names are correct in configuration

## Uninstalling

### Uninstall All Services

To remove the complete sandbox environment:

```bash
# Uninstall all services from namespace
helm uninstall ev-charging-bap --namespace ev-charging-sandbox
helm uninstall ev-charging-bpp --namespace ev-charging-sandbox
helm uninstall mock-registry --namespace ev-charging-sandbox
helm uninstall mock-cds --namespace ev-charging-sandbox
helm uninstall mock-bap --namespace ev-charging-sandbox
helm uninstall mock-bpp --namespace ev-charging-sandbox

# Or uninstall all in one command
helm uninstall ev-charging-bap ev-charging-bpp mock-registry mock-cds mock-bap mock-bpp \
  --namespace ev-charging-sandbox

# Remove namespace (optional - removes all resources in namespace)
kubectl delete namespace ev-charging-sandbox

# Or remove specific resources (if not deleting namespace)
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic
kubectl delete configmap -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic
kubectl delete pvc -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic
```

### Uninstall Individual Services

```bash
# Uninstall BAP (default namespace)
helm uninstall ev-charging-bap

# Uninstall BPP (default namespace)
helm uninstall ev-charging-bpp

# Uninstall from specific namespace
helm uninstall ev-charging-bap --namespace ev-charging-sandbox
helm uninstall ev-charging-bpp --namespace ev-charging-sandbox

# Uninstall mock services
helm uninstall mock-registry --namespace ev-charging-sandbox
helm uninstall mock-cds --namespace ev-charging-sandbox
helm uninstall mock-bap --namespace ev-charging-sandbox
helm uninstall mock-bpp --namespace ev-charging-sandbox

# Remove associated resources (if needed)
kubectl delete all -l app.kubernetes.io/name=onix-api-monolithic
kubectl delete all -n ev-charging-sandbox -l app.kubernetes.io/name=onix-api-monolithic  # If using namespace
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Main Helm Chart README](../../../../helm/api/monolithic/README.md) - Detailed Helm chart documentation
- [Docker Sandbox README](../../../docker/api/monolithic/README.md) - Docker Compose equivalent setup

## Notes

- Service names in Kubernetes use DNS resolution within the cluster
- All services communicate using Kubernetes service names (e.g., `ev-charging-mock-registry:3030`)
- Configuration is managed through Helm values files and ConfigMaps
- **Monolithic Architecture**: Single service handles all endpoints:
  - `ev-charging-mock-bap` handles all BAP callbacks (on_discover, on_select, on_init, etc.)
  - `ev-charging-mock-bpp` handles all BPP requests (discover, select, init, confirm, etc.)
- Production deployments should use proper secrets management for keys and credentials

