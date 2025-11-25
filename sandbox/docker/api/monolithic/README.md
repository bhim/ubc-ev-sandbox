# EV Charging Sandbox - Unified Docker Compose Setup

This directory contains a unified Docker Compose configuration that sets up a complete EV Charging sandbox environment with all necessary services: API adapters (BAP and BPP), mock services (CDS, Registry, BAP, BPP), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol. The architecture includes:

- **ONIX Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider)
- **Mock Services**: Simulated services for testing without real implementations
- **Supporting Services**: Redis for caching and state management

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

5. **mock-registry** (Port: 3030)
   - Mock implementation of the network registry service
   - Maintains a registry of all BAPs, BPPs, and CDS services on the network
   - Provides subscriber lookup and key management functionality

6. **mock-cds** (Port: 8082)
   - Mock Catalog Discovery Service (CDS)
   - Aggregates discover requests from BAPs and broadcasts to registered BPPs
   - Collects and aggregates responses from multiple BPPs
   - Handles signature verification and signing

7. **mock-bap** (Port: 9001)
   - Mock BAP backend service
   - Simulates a Buyer App Provider application
   - Receives callbacks from the ONIX adapter

8. **mock-bpp** (Port: 9002)
   - Mock BPP backend service
   - Simulates a Buyer Platform Provider application
   - Handles requests from the ONIX adapter

## Configuration Files

Each service has its own configuration file with a service name prefix. This section explains what each config file is used for:

### 1. ONIX BAP Configuration (`docker/api/monolithic/config/onix-bap/`)

**Purpose**: Complete adapter configuration for the ONIX BAP plugin.

**Usage**: The actual configuration files are mounted from `../../../../docker/api/monolithic/config/onix-bap/`. This directory contains:

- **`adapter.yaml`**: Main adapter configuration file
- **`bap_caller_routing.yaml`**: Routing rules for outgoing requests from BAP application
- **`bap_receiver_routing.yaml`**: Routing rules for incoming callbacks to BAP

**Key Sections in `adapter.yaml`**:
- **`appName`**: Application identifier ("onix-ev-charging")
- **`log`**: Logging configuration (level, destinations, context keys)
- **`http`**: HTTP server settings (port: 8001, timeouts)
- **`modules`**: Two main modules:
  - **`bapTxnReceiver`**: Handles incoming callbacks from CDS/BPPs
    - Validates signatures
    - Routes to backend (mock-bap)
    - Validates schemas
  - **`bapTxnCaller`**: Handles outgoing requests from BAP application
    - Routes requests using `bap_caller_routing.yaml`
    - Signs requests
- **`plugins`**: Plugin configuration including:
  - Registry connection to mock-registry
  - Key manager for signing/encryption
  - Redis cache configuration
  - Schema validator
  - Router for request routing

**Routing Configuration Files**:
- **`bap_caller_routing.yaml`**: Defines routing rules for outgoing requests:
  - Phase 1: `discover` → Routes to CDS (`http://mock-cds:8082/csd`)
  - Phase 2+: Other actions (`select`, `init`, `confirm`, etc.) → Routes directly to BPP using context endpoint
- **`bap_receiver_routing.yaml`**: Defines routing rules for incoming callbacks:
  - All callbacks (`on_discover`, `on_select`, `on_init`, etc.) → Routes to mock-bap backend (`http://mock-bap:9001`)

**Note**: The reference files `onix-bap_config.yml` in this directory are informational only. The actual configs are in `docker/api/monolithic/config/onix-bap/`.

### 2. ONIX BPP Configuration (`docker/api/monolithic/config/onix-bpp/`)

**Purpose**: Complete adapter configuration for the ONIX BPP plugin.

**Usage**: The actual configuration files are mounted from `../../../../docker/api/monolithic/config/onix-bpp/`. This directory contains:

- **`adapter.yaml`**: Main adapter configuration file
- **`bpp_caller_routing.yaml`**: Routing rules for outgoing responses from BPP
- **`bpp_receiver_routing.yaml`**: Routing rules for incoming requests to BPP

**Key Sections in `adapter.yaml`**:
- **`appName`**: Application identifier ("bpp-ev-charging")
- **`log`**: Logging configuration
- **`http`**: HTTP server settings (port: 8002, timeouts)
- **`modules`**: Two main modules:
  - **`bppTxnReceiver`**: Handles incoming requests from CDS/BAPs
    - Validates signatures
    - Routes to backend (mock-bpp)
    - Validates schemas
  - **`bppTxnCaller`**: Handles outgoing responses to CDS/BAPs
    - Routes responses using `bpp_caller_routing.yaml`
    - Signs responses
- **`plugins`**: Similar plugin configuration as BAP, but for BPP role

**Routing Configuration Files**:
- **`bpp_caller_routing.yaml`**: Defines routing rules for outgoing responses:
  - Phase 1: `on_discover` → Routes to CDS (`http://mock-cds:8082/csd`) for aggregation
  - Phase 2+: Other responses (`on_select`, `on_init`, `on_confirm`, etc.) → Routes directly to BAP using context endpoint
- **`bpp_receiver_routing.yaml`**: Defines routing rules for incoming requests:
  - Phase 1: `discover` from CDS → Routes to mock-bpp backend (`http://mock-bpp:9002`)
  - Phase 2+: Other requests (`select`, `init`, `confirm`, etc.) from BAP → Routes to mock-bpp backend

**Note**: The reference files `onix-bpp_config.yml` in this directory are informational only. The actual configs are in `docker/api/monolithic/config/onix-bpp/`.

### 3. `mock-registry_config.yml`

**Purpose**: Configuration for the mock registry service that maintains the network participant registry.

**Usage**: Mounted into the mock-registry container at `/app/config/config.yaml`.

**Key Sections**:
- **`server.port`**: Server port (3030)
- **`subscribers`**: List of all network participants:
  - **BAPs**: mock-bap, onix-bap, example-bap.com
  - **BPPs**: mock-bpp, onix-bpp, example-bpp.com, chargezone-energy-bpp.com
  - **CDS**: mock-cds
  - Each subscriber has:
    - `subscriber_id`: Unique identifier
    - `subscriber_uri`: Endpoint URL
    - `type`: BAP, BPP, or CDS
    - `signing_public_key` / `encr_public_key`: For signature verification (external subscribers)
    - `key_id`: Key identifier
- **`defaults`**: Validity period for registry entries

**When to Modify**:
- Add new BAPs, BPPs, or CDS services to the network
- Update subscriber URIs if services move
- Update keys when rotating encryption/signing keys
- Modify validity periods

### 4. `mock-cds_config.yml`

**Purpose**: Configuration for the mock Catalog Discovery Service that aggregates discover requests.

**Usage**: Mounted into the mock-cds container at `/app/config/config.yaml`.

**Key Sections**:
- **`server.port`**: Server port (8082)
- **`registry`**: Registry service connection:
  - `host`: mock-registry
  - `port`: 3030
  - `lookup_path`: /lookup
- **`cds.signing`**: CDS signing keys:
  - `private_key`: For signing aggregated responses
  - `public_key`: For signature verification
  - `subscriber_id`: "mock-cds"
  - `key_id`: "cds-key-1"
  - `verify_signatures`: Enable signature verification
- **`endpoints.bpps`**: List of BPP endpoints to broadcast discover requests to:
  - `host`: BPP service hostname
  - `port`: BPP service port
  - `discover_path`: Path for discover endpoint
  - `subscriber_id`: BPP subscriber ID
- **`timing`**: Timing configuration:
  - `broadcast_discover_delay_ms`: Delay before broadcasting (500ms)
  - `aggregate_response_delay_ms`: Delay before aggregating responses (1000ms)
  - `signature_expiry_minutes`: Signature expiry time (5 minutes)
- **`defaults`**: Default values for requests:
  - `version`: Protocol version ("1.0.0")
  - `country_code`: "IND"
  - `city_code`: "std:080"
  - `default_gps`: Default GPS coordinates

**When to Modify**:
- Add or remove BPP endpoints to broadcast to
- Update signing keys
- Adjust timing delays for testing
- Change default location/version values

### 5. `mock-bap_config.yml`

**Purpose**: Configuration for the mock BAP backend service.

**Usage**: Mounted into the mock-bap container at `/app/config/config.yaml`.

**Key Sections**:
- **`server.port`**: Server port (9001)
- **`defaults`**: Default values:
  - `version`: Protocol version ("1.0.0")
  - `country_code`: "IND"
  - `city_code`: "std:080"

**When to Modify**:
- Change server port
- Update default version or location codes

### 6. `mock-bpp_config.yml`

**Purpose**: Configuration for the mock BPP backend service.

**Usage**: Mounted into the mock-bpp container at `/app/config/config.yaml`.

**Key Sections**:
- **`server.port`**: Server port (9002)
- **`defaults`**: Default values:
  - `version`: Protocol version ("1.0.0")
  - `country_code`: "IND"
  - `city_code`: "std:080"

**When to Modify**:
- Change server port
- Update default version or location codes

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Access to Docker images (pulled automatically)

### Starting All Services

```bash
# Navigate to this directory
cd sandbox/docker/api/monolithic

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Service Endpoints

Once all services are running, you can access:

| Service | Endpoint | Description |
|---------|----------|-------------|
| **ONIX BAP** | `http://localhost:8001` | BAP adapter endpoints |
| | `http://localhost:8001/bap/caller/{action}` | Send requests from BAP |
| | `http://localhost:8001/bap/receiver/{action}` | Receive callbacks |
| **ONIX BPP** | `http://localhost:8002` | BPP adapter endpoints |
| | `http://localhost:8002/bpp/caller/{action}` | Send responses |
| | `http://localhost:8002/bpp/receiver/{action}` | Receive requests |
| **Mock Registry** | `http://localhost:3030` | Registry service |
| | `http://localhost:3030/lookup` | Lookup subscribers |
| **Mock CDS** | `http://localhost:8082` | Catalog Discovery Service |
| | `http://localhost:8082/csd` | CDS aggregation endpoint |
| **Mock BAP** | `http://localhost:9001` | Mock BAP backend |
| **Mock BPP** | `http://localhost:9002` | Mock BPP backend |

## Configuration Workflow

1. **Service Discovery Flow**:
   - BAP sends discover request → ONIX BAP adapter
   - ONIX BAP routes to → Mock CDS
   - Mock CDS broadcasts to → All registered BPPs
   - BPPs respond → Mock CDS aggregates
   - Mock CDS sends aggregated response → ONIX BAP → Mock BAP

2. **Transaction Flow** (Phase 2+):
   - BAP sends select/init/confirm → ONIX BAP adapter
   - ONIX BAP routes directly to → ONIX BPP (bypasses CDS)
   - ONIX BPP forwards to → Mock BPP backend
   - Mock BPP responds → ONIX BPP
   - ONIX BPP routes callback → ONIX BAP → Mock BAP

## Network Architecture

All services run on a shared Docker network (`onix-network`) allowing:
- Service-to-service communication using container names as hostnames
- Isolated networking from other Docker containers
- Easy service discovery without IP address management

## Customization

### Adding New BPP Endpoints

1. Edit `mock-cds_config.yml`:
   ```yaml
   endpoints:
     bpps:
       - host: "new-bpp-service"
         port: "8002"
         discover_path: "/bpp/receiver/discover"
         subscriber_id: "new-bpp-id"
   ```

2. Add the BPP to `mock-registry_config.yml`:
   ```yaml
   subscribers:
     - subscriber_id: "new-bpp-id"
       subscriber_uri: "http://new-bpp-service:8002"
       type: "BPP"
   ```

3. Restart services:
   ```bash
   docker-compose restart mock-cds mock-registry
   ```

### Changing Service Ports

Edit `docker-compose.yml` and update the port mappings:
```yaml
ports:
  - "NEW_PORT:CONTAINER_PORT"
```

**Important**: Also update the corresponding config files if services reference each other's ports. This includes:
- Mock service config files (if port changes)
- ONIX adapter routing configuration files if they reference service ports directly

### Modifying ONIX Adapter Routing

To change how requests/responses are routed through the ONIX adapters, edit the routing configuration files:

1. **For BAP routing changes**, edit `docker/api/monolithic/config/onix-bap/`:
   - `bap_caller_routing.yaml` - Modify outgoing request routing
   - `bap_receiver_routing.yaml` - Modify incoming callback routing

2. **For BPP routing changes**, edit `docker/api/monolithic/config/onix-bpp/`:
   - `bpp_caller_routing.yaml` - Modify outgoing response routing
   - `bpp_receiver_routing.yaml` - Modify incoming request routing

3. **Restart the adapter services**:
   ```bash
   docker-compose restart onix-bap-plugin onix-bpp-plugin
   ```

**Note**: The routing files use YAML format with `routingRules` sections. Each rule specifies domain, version, target type (url or bap/bpp), and endpoints.

### Updating Signing Keys

1. Generate new key pairs for the service
2. Update the service's config file (e.g., `mock-cds_config.yml`)
3. Update `mock-registry_config.yml` with the new public key
4. Restart affected services

## Troubleshooting

### Service Won't Start

1. **Check ports are available**:
   ```bash
   lsof -i :8001  # BAP
   lsof -i :8002  # BPP
   lsof -i :3030  # Registry
   lsof -i :8082  # CDS
   ```

2. **Check container logs**:
   ```bash
   docker-compose logs <service-name>
   ```

3. **Verify health checks**:
   ```bash
   docker-compose ps
   ```

### Configuration Issues

1. **Verify config files are mounted**:
   ```bash
   # Check ONIX adapter configs
   docker exec onix-bap-plugin ls -la /app/config/
   docker exec onix-bap-plugin ls -la /app/config/onix-bap/
   
   # Check mock service configs
   docker exec mock-registry ls -la /app/config/
   ```

2. **Check config file syntax**:
   ```bash
   # View adapter configuration
   docker exec onix-bap-plugin cat /app/config/adapter.yaml
   
   # View routing configurations
   docker exec onix-bap-plugin cat /app/config/onix-bap/bap_caller_routing.yaml
   docker exec onix-bap-plugin cat /app/config/onix-bap/bap_receiver_routing.yaml
   
   # View mock service configs
   docker exec mock-registry cat /app/config/config.yaml
   ```

### Registry Lookup Failures

1. **Verify registry is running**:
   ```bash
   curl http://localhost:3030/health
   ```

2. **Check subscriber registration**:
   ```bash
   curl http://localhost:3030/lookup?subscriber_id=mock-bap
   ```

3. **Verify subscriber URIs are reachable from registry**:
   - Check network connectivity
   - Verify service names match container names

## File Structure

```
sandbox/docker/api/monolithic/
├── docker-compose.yml              # Unified compose file for all services
├── README.md                        # This file
├── onix-bap_config.yml              # Reference config for ONIX BAP (informational)
├── onix-bpp_config.yml              # Reference config for ONIX BPP (informational)
├── mock-registry_config.yml         # Mock registry configuration
├── mock-cds_config.yml              # Mock CDS configuration
├── mock-bap_config.yml              # Mock BAP configuration
└── mock-bpp_config.yml              # Mock BPP configuration

# Actual ONIX adapter configurations (mounted from parent directory)
docker/api/monolithic/config/
├── onix-bap/
│   ├── adapter.yaml                 # Main BAP adapter configuration
│   ├── bap_caller_routing.yaml      # BAP caller routing rules
│   └── bap_receiver_routing.yaml    # BAP receiver routing rules
└── onix-bpp/
    ├── adapter.yaml                 # Main BPP adapter configuration
    ├── bpp_caller_routing.yaml      # BPP caller routing rules
    └── bpp_receiver_routing.yaml    # BPP receiver routing rules
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Main API README](../../../../../docker/api/monolithic/README.md) - Detailed ONIX adapter documentation

## Notes

- The `onix-bap_config.yml` and `onix-bpp_config.yml` files are **reference copies** for documentation purposes. The actual configurations used by the containers are mounted from `../../../../docker/api/monolithic/config/onix-{bap|bpp}/`.
- The ONIX adapter configuration directory structure includes:
  - `adapter.yaml`: Main adapter configuration
  - `{bap|bpp}_caller_routing.yaml`: Routing rules for outgoing requests/responses
  - `{bap|bpp}_receiver_routing.yaml`: Routing rules for incoming requests/responses
- Volume mounts:
  - Entire config directory: `/app/config/onix-{bap|bpp}` (for routing files)
  - Adapter config separately: `/app/config/adapter.yaml` (for main config)
  - Schema directory: `/app/schemas` (read-only, from root `schemas/` directory)
- All mock services use simplified configurations suitable for testing.
- Production deployments should use proper key management and secure configurations.
- Network service discovery uses Docker container names, which must match the service names in configuration files.

