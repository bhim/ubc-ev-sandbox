# EV Charging Sandbox - Microservice Architecture Docker Compose Setup

This directory contains a unified Docker Compose configuration that sets up a complete EV Charging sandbox environment with all necessary services: API adapters (BAP and BPP), mock services (CDS, Registry, multiple BAP and BPP instances), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol in a **microservice architecture**. In this architecture, each endpoint routes to different mock services, allowing for:

- **Centralized Management**: Single adapter service handles all endpoints
- **Flexible Routing**: Each endpoint can route to different mock services for testing
- **Easy Configuration**: Routing changes only require updating YAML files
- **Resource Efficiency**: Single service instance handles all endpoints

The architecture includes:

- **ONIX Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider)
- **Mock Services**: Multiple simulated services (one per endpoint) for testing without real implementations
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

7. **Mock BAP Services** (Internal Port: 9001, External Ports: 9001-9010)
   - Multiple mock BAP backend services, one per endpoint:
     - `mock-bap-discover` (Port: 9001) - Handles on_discover callbacks
     - `mock-bap-select` (Port: 9002) - Handles on_select callbacks
     - `mock-bap-init` (Port: 9003) - Handles on_init callbacks
     - `mock-bap-confirm` (Port: 9004) - Handles on_confirm callbacks
     - `mock-bap-status` (Port: 9005) - Handles on_status callbacks
     - `mock-bap-track` (Port: 9006) - Handles on_track callbacks
     - `mock-bap-cancel` (Port: 9007) - Handles on_cancel callbacks
     - `mock-bap-update` (Port: 9008) - Handles on_update callbacks
     - `mock-bap-rating` (Port: 9009) - Handles on_rating callbacks
     - `mock-bap-support` (Port: 9010) - Handles on_support callbacks
   - Each service simulates a Buyer App Provider application endpoint
   - Receives callbacks from the ONIX adapter based on routing configuration

8. **Mock BPP Services** (Internal Port: 9002, External Ports: 9011-9020)
   - Multiple mock BPP backend services, one per endpoint:
     - `mock-bpp-discover` (Port: 9011) - Handles discover requests
     - `mock-bpp-select` (Port: 9012) - Handles select requests
     - `mock-bpp-init` (Port: 9013) - Handles init requests
     - `mock-bpp-confirm` (Port: 9014) - Handles confirm requests
     - `mock-bpp-status` (Port: 9015) - Handles status requests
     - `mock-bpp-track` (Port: 9016) - Handles track requests
     - `mock-bpp-cancel` (Port: 9017) - Handles cancel requests
     - `mock-bpp-update` (Port: 9018) - Handles update requests
     - `mock-bpp-rating` (Port: 9019) - Handles rating requests
     - `mock-bpp-support` (Port: 9020) - Handles support requests
   - Each service simulates a Buyer Platform Provider application endpoint
   - Handles requests from the ONIX adapter based on routing configuration

## Configuration Files

Each service has its own configuration file with a service name prefix. This section explains what each config file is used for:

### 1. ONIX BAP Configuration (`docker/api/microservice/config/onix-bap/`)

**Purpose**: Complete adapter configuration for the ONIX BAP plugin.

**Usage**: The actual configuration files are mounted from `../../../../docker/api/microservice/config/onix-bap/`. This directory contains:

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
- **`bap_caller_routing.yaml`**: Defines routing rules for outgoing requests (microservice architecture):
  - Phase 1: `discover` → Routes to CDS (`http://mock-cds:8082/csd`)
  - Phase 2+: Each action routes to onix-bpp-plugin receiver, which then routes to different mock BPP services:
    - `select` → `http://onix-bpp-plugin:8002/bpp/receiver/select` → `mock-bpp-select:9002`
    - `init` → `http://onix-bpp-plugin:8002/bpp/receiver/init` → `mock-bpp-init:9002`
    - `confirm` → `http://onix-bpp-plugin:8002/bpp/receiver/confirm` → `mock-bpp-confirm:9002`
    - `update` → `http://onix-bpp-plugin:8002/bpp/receiver/update` → `mock-bpp-update:9002`
    - `track` → `http://onix-bpp-plugin:8002/bpp/receiver/track` → `mock-bpp-track:9002`
    - `cancel` → `http://onix-bpp-plugin:8002/bpp/receiver/cancel` → `mock-bpp-cancel:9002`
    - `rating` → `http://onix-bpp-plugin:8002/bpp/receiver/rating` → `mock-bpp-rating:9002`
    - `support` → `http://onix-bpp-plugin:8002/bpp/receiver/support` → `mock-bpp-support:9002`
- **`bap_receiver_routing.yaml`**: Defines routing rules for incoming callbacks (microservice architecture):
  - Each callback routes to a different mock BAP service:
    - `on_discover` → `http://mock-bap-discover:9001`
    - `on_select` → `http://mock-bap-select:9001`
    - `on_init` → `http://mock-bap-init:9001`
    - `on_confirm` → `http://mock-bap-confirm:9001`
    - `on_status` → `http://mock-bap-status:9001`
    - `on_track` → `http://mock-bap-track:9001`
    - `on_cancel` → `http://mock-bap-cancel:9001`
    - `on_update` → `http://mock-bap-update:9001`
    - `on_rating` → `http://mock-bap-rating:9001`
    - `on_support` → `http://mock-bap-support:9001`

**Note**: The reference files `onix-bap_config.yml` in this directory are informational only. The actual configs are in `docker/api/microservice/config/onix-bap/`.

### 2. ONIX BPP Configuration (`docker/api/microservice/config/onix-bpp/`)

**Purpose**: Complete adapter configuration for the ONIX BPP plugin.

**Usage**: The actual configuration files are mounted from `../../../../docker/api/microservice/config/onix-bpp/`. This directory contains:

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
- **`bpp_caller_routing.yaml`**: Defines routing rules for outgoing responses (microservice architecture):
  - Phase 1: `on_discover` → Routes to CDS (`http://mock-cds:8082/csd`) for aggregation
  - Phase 2+: Each response routes to onix-bap-plugin receiver, which then routes to different mock BAP services:
    - `on_select` → `http://onix-bap-plugin:8001/bap/receiver/on_select` → `mock-bap-select:9001`
    - `on_init` → `http://onix-bap-plugin:8001/bap/receiver/on_init` → `mock-bap-init:9001`
    - `on_confirm` → `http://onix-bap-plugin:8001/bap/receiver/on_confirm` → `mock-bap-confirm:9001`
    - `on_status` → `http://onix-bap-plugin:8001/bap/receiver/on_status` → `mock-bap-status:9001`
    - `on_track` → `http://onix-bap-plugin:8001/bap/receiver/on_track` → `mock-bap-track:9001`
    - `on_cancel` → `http://onix-bap-plugin:8001/bap/receiver/on_cancel` → `mock-bap-cancel:9001`
    - `on_update` → `http://onix-bap-plugin:8001/bap/receiver/on_update` → `mock-bap-update:9001`
    - `on_rating` → `http://onix-bap-plugin:8001/bap/receiver/on_rating` → `mock-bap-rating:9001`
    - `on_support` → `http://onix-bap-plugin:8001/bap/receiver/on_support` → `mock-bap-support:9001`
- **`bpp_receiver_routing.yaml`**: Defines routing rules for incoming requests (microservice architecture):
  - Phase 1: `discover` from CDS → Routes to `http://mock-bpp-discover:9002`
  - Phase 2+: Each request routes to a different mock BPP service:
    - `select` → `http://mock-bpp-select:9002`
    - `init` → `http://mock-bpp-init:9002`
    - `confirm` → `http://mock-bpp-confirm:9002`
    - `status` → `http://mock-bpp-status:9002`
    - `track` → `http://mock-bpp-track:9002`
    - `cancel` → `http://mock-bpp-cancel:9002`
    - `update` → `http://mock-bpp-update:9002`
    - `rating` → `http://mock-bpp-rating:9002`
    - `support` → `http://mock-bpp-support:9002`

**Note**: The reference files `onix-bpp_config.yml` in this directory are informational only. The actual configs are in `docker/api/microservice/config/onix-bpp/`.

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
cd sandbox/docker/api/microservice

# Start all services (includes 20 mock services - 10 BAP + 10 BPP)
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps

# View logs for specific services
docker-compose logs -f onix-bap-plugin
docker-compose logs -f mock-bap-select
docker-compose logs -f mock-bpp-select
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
| **Mock BAP Services** | `http://localhost:9001` | mock-bap-discover |
| | `http://localhost:9002` | mock-bap-select |
| | `http://localhost:9003` | mock-bap-init |
| | `http://localhost:9004` | mock-bap-confirm |
| | `http://localhost:9005` | mock-bap-status |
| | `http://localhost:9006` | mock-bap-track |
| | `http://localhost:9007` | mock-bap-cancel |
| | `http://localhost:9008` | mock-bap-update |
| | `http://localhost:9009` | mock-bap-rating |
| | `http://localhost:9010` | mock-bap-support |
| **Mock BPP Services** | `http://localhost:9011` | mock-bpp-discover |
| | `http://localhost:9012` | mock-bpp-select |
| | `http://localhost:9013` | mock-bpp-init |
| | `http://localhost:9014` | mock-bpp-confirm |
| | `http://localhost:9015` | mock-bpp-status |
| | `http://localhost:9016` | mock-bpp-track |
| | `http://localhost:9017` | mock-bpp-cancel |
| | `http://localhost:9018` | mock-bpp-update |
| | `http://localhost:9019` | mock-bpp-rating |
| | `http://localhost:9020` | mock-bpp-support |

## Configuration Workflow

1. **Service Discovery Flow** (Phase 1):
   - BAP sends discover request → ONIX BAP adapter
   - ONIX BAP routes to → Mock CDS
   - Mock CDS broadcasts to → All registered BPPs (mock-bpp-discover)
   - BPPs respond → Mock CDS aggregates
   - Mock CDS sends aggregated response → ONIX BAP → mock-bap-discover

2. **Transaction Flow** (Phase 2+ - Microservice Architecture):
   - BAP sends select/init/confirm → ONIX BAP adapter (onix-bap-plugin)
   - ONIX BAP routes to → ONIX BPP receiver (onix-bpp-plugin/bpp/receiver/{action})
   - ONIX BPP receiver routes to → Specific Mock BPP backend service (e.g., mock-bpp-select:9002)
   - Mock BPP responds → ONIX BPP caller
   - ONIX BPP caller routes callback to → ONIX BAP receiver (onix-bap-plugin/bap/receiver/on_{action})
   - ONIX BAP receiver routes to → Specific Mock BAP service (e.g., mock-bap-select:9001)

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

1. **For BAP routing changes**, edit `docker/api/microservice/config/onix-bap/`:
   - `bap_caller_routing.yaml` - Modify outgoing request routing (each endpoint routes to different mock BPP services)
   - `bap_receiver_routing.yaml` - Modify incoming callback routing (each callback routes to different mock BAP services)

2. **For BPP routing changes**, edit `docker/api/microservice/config/onix-bpp/`:
   - `bpp_caller_routing.yaml` - Modify outgoing response routing (each response routes to different mock BAP services)
   - `bpp_receiver_routing.yaml` - Modify incoming request routing (each request routes to different mock BPP services)

3. **Restart the adapter services**:
   ```bash
   docker-compose restart onix-bap-plugin onix-bpp-plugin
   ```

**Note**: The routing files use YAML format with `routingRules` sections. Each rule specifies domain, version, target type (url), and endpoints. In microservice architecture, each endpoint/callback has its own routing rule pointing to a specific mock service.

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
sandbox/docker/api/microservice/
├── docker-compose.yml              # Unified compose file for all services
├── README.md                        # This file
├── onix-bap_config.yml              # Reference config for ONIX BAP (informational)
├── onix-bpp_config.yml              # Reference config for ONIX BPP (informational)
├── mock-registry_config.yml         # Mock registry configuration
├── mock-cds_config.yml              # Mock CDS configuration
├── mock-bap_config.yml              # Mock BAP configuration (shared by all mock-bap-* services)
└── mock-bpp_config.yml              # Mock BPP configuration (shared by all mock-bpp-* services)

# Actual ONIX adapter configurations (mounted from parent directory)
docker/api/microservice/config/
├── onix-bap/
│   ├── adapter.yaml                 # Main BAP adapter configuration
│   ├── bap_caller_routing.yaml      # BAP caller routing rules (microservice: routes to different mock-bpp-* services)
│   └── bap_receiver_routing.yaml    # BAP receiver routing rules (microservice: routes to different mock-bap-* services)
└── onix-bpp/
    ├── adapter.yaml                 # Main BPP adapter configuration
    ├── bpp_caller_routing.yaml      # BPP caller routing rules (microservice: routes to different mock-bap-* services)
    └── bpp_receiver_routing.yaml    # BPP receiver routing rules (microservice: routes to different mock-bpp-* services)
```

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Main API README](../../../../../docker/api/microservice/README.md) - Detailed ONIX adapter documentation

## Notes

- The `onix-bap_config.yml` and `onix-bpp_config.yml` files are **reference copies** for documentation purposes. The actual configurations used by the containers are mounted from `../../../../docker/api/microservice/config/onix-{bap|bpp}/`.
- The ONIX adapter configuration directory structure includes:
  - `adapter.yaml`: Main adapter configuration
  - `{bap|bpp}_caller_routing.yaml`: Routing rules for outgoing requests/responses (microservice: each endpoint routes to different mock services)
  - `{bap|bpp}_receiver_routing.yaml`: Routing rules for incoming requests/responses (microservice: each callback/request routes to different mock services)
- Volume mounts:
  - Entire config directory: `/app/config/onix-{bap|bpp}` (for routing files)
  - Adapter config separately: `/app/config/adapter.yaml` (for main config)
  - Schema directory: `/app/schemas` (read-only, from root `schemas/` directory)
- **Microservice Architecture**: Each endpoint has its own mock service instance:
  - 10 mock-bap services (mock-bap-discover through mock-bap-support)
  - 10 mock-bpp services (mock-bpp-discover through mock-bpp-support)
  - All services share the same configuration file but run as separate containers
  - Internal communication uses container names (e.g., `mock-bap-select:9001`)
- All mock services use simplified configurations suitable for testing.
- Production deployments should use proper key management and secure configurations.
- Network service discovery uses Docker container names, which must match the service names in routing configuration files.

