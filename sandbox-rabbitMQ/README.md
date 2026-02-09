# EV Charging Sandbox - RabbitMQ Docker Compose Setup

This directory contains Docker Compose configurations for setting up a complete EV Charging sandbox environment with RabbitMQ message broker integration. The setup includes ONIX adapters (BAP and BPP), mock services (CDS, Registry, BAP-RabbitMQ, BPP-RabbitMQ), and supporting infrastructure.

## Architecture Overview

This setup creates a fully functional sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol with RabbitMQ for asynchronous message processing. The architecture includes:

- **ONIX RabbitMQ Adapters**: Protocol adapters for BAP (Buyer App Provider) and BPP (Buyer Platform Provider) that consume and publish messages via RabbitMQ
- **Mock Services**: Simulated services for testing without real implementations
- **RabbitMQ Message Broker**: Central message broker for asynchronous communication
- **Supporting Services**: Redis for caching and state management

## Services

### Core Services

1. **rabbitmq** (Ports: 5672 AMQP, 15672 Management UI)
   - RabbitMQ message broker for asynchronous communication
   - Used for message routing between adapters and mock services
   - Management UI available at `http://localhost:15672` (guest/guest)

2. **redis-bap** (Port: 6379)
   - Redis cache for the BAP adapter
   - Used for storing transaction state, caching registry lookups, and session management

3. **redis-bpp** (Port: 6380)
   - Redis cache for the BPP adapter
   - Used for storing transaction state, caching registry lookups, and session management

4. **onix-bap-plugin-rabbitmq**
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

8. **mock-bap-rabbit-mq** (Internal Port: 9003)
   - Mock BAP backend service with RabbitMQ integration
   - Simulates a Buyer App Provider application
   - Consumes messages from RabbitMQ queues (routing keys: `bap.on_discover`, `bap.on_select`, etc.)
   - Publishes requests to RabbitMQ for ONIX adapter processing
   - **Note**: Runs in queue-only mode - no external HTTP ports exposed

9. **mock-bpp-rabbit-mq** (Internal Port: 9004)
   - Mock BPP backend service with RabbitMQ integration
   - Simulates a Buyer Platform Provider application
   - Consumes messages from RabbitMQ queues (routing keys: `bpp.discover`, `bpp.select`, etc.) - Note: These are published by BPP Plugin, not BAP Backend
   - Publishes responses to RabbitMQ for ONIX adapter processing
   - **Note**: Runs in queue-only mode - no external HTTP ports exposed

## Configuration Files

### 1. ONIX BAP RabbitMQ Configuration (`docker/rabbitmq/config/onix-bap/`)

**Purpose**: Complete adapter configuration for the ONIX BAP RabbitMQ plugin.

**Usage**: The actual configuration files are mounted from `../../../../docker/rabbitmq/config/onix-bap/`. This directory contains:

- **`adapter.yaml`**: Main adapter configuration file
- **`bapTxnCaller-routing.yaml`**: Routing rules for outgoing requests from BAP application
- **`bapTxnReciever-routing.yaml`**: Routing rules for incoming callbacks to BAP
- **`plugin.yaml`**: Plugin-specific configuration

### 2. ONIX BPP RabbitMQ Configuration (`docker/rabbitmq/config/onix-bpp/`)

**Purpose**: Complete adapter configuration for the ONIX BPP RabbitMQ plugin.

**Usage**: The actual configuration files are mounted from `../../../../docker/rabbitmq/config/onix-bpp/`. This directory contains:

- **`adapter.yaml`**: Main adapter configuration file
- **`bppTxnCaller-routing.yaml`**: Routing rules for outgoing responses from BPP
- **`bppTxnReciever-routing.yaml`**: Routing rules for incoming requests to BPP
- **`plugin.yaml`**: Plugin-specific configuration

### 3. `mock-registry_config.yml`

**Purpose**: Configuration for the mock registry service that maintains the network participant registry.

**Usage**: Mounted into the mock-registry container at `/app/config/config.yaml`.

### 4. `mock-cds_config.yml`

**Purpose**: Configuration for the mock Catalog Discovery Service that aggregates discover requests.

**Usage**: Mounted into the mock-cds container at `/app/config/config.yaml`.

### 5. `mock-bap-rabbitMq_config.yml`

**Purpose**: Configuration for the mock BAP backend service with RabbitMQ integration.

**Usage**: Mounted into the mock-bap-rabbit-mq container at `/app/config/config.yaml`.

### 6. `mock-bpp-rabbitMq_config.yml`

**Purpose**: Configuration for the mock BPP backend service with RabbitMQ integration.

**Usage**: Mounted into the mock-bpp-rabbit-mq container at `/app/config/config.yaml`.

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Access to Docker images (pulled automatically)

### Starting All Services

```bash
# Navigate to this directory
cd sandbox/docker/rabbitmq

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### Viewing Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f onix-bap-plugin-rabbitmq
docker-compose logs -f mock-bap-rabbit-mq
```

### Checking Service Status

```bash
# Check all services
docker-compose ps

# Check RabbitMQ management UI
# Open http://localhost:15672 (guest/guest)
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Stop specific services
docker-compose stop onix-bap-plugin-rabbitmq
```

## Service Endpoints

Once all services are running, you can access:

| Service | Endpoint | Description |
|---------|----------|-------------|
| **RabbitMQ Management** | `http://localhost:15672` | RabbitMQ Management UI (guest/guest) |
| **Mock Registry** | `http://localhost:3030` | Registry service |
| | `http://localhost:3030/lookup` | Lookup subscribers |
| **Mock CDS** | `http://localhost:8082` | Catalog Discovery Service |
| | `http://localhost:8082/csd` | CDS aggregation endpoint |
| **ONIX BAP Plugin** | `http://localhost:8001` | HTTP endpoint for bapTxnReceiver |
| **ONIX BPP Plugin** | `http://localhost:8002` | HTTP endpoint for bppTxnReceiver |
| **Mock BAP RabbitMQ** | Queue-based | Consumes from RabbitMQ queues |
| **Mock BPP RabbitMQ** | Queue-based | Consumes from RabbitMQ queues |

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

### Accessing the Management UI

1. **Start the services**:
   ```bash
   cd sandbox/docker/rabbitmq
   docker-compose up -d
   ```

2. **Open the Management UI**:
   - URL: `http://localhost:15672`
   - Username: `guest`
   - Password: `guest`

## Troubleshooting

### Service Won't Start

1. **Check ports are available**:
   ```bash
   lsof -i :5672   # RabbitMQ AMQP
   lsof -i :15672  # RabbitMQ Management
   lsof -i :6379   # Redis BAP
   lsof -i :6380   # Redis BPP
   ```

2. **Check container logs**:
   ```bash
   docker-compose logs <service-name>
   ```

### Configuration Issues

1. **Verify config files are mounted**:
   ```bash
   # Check ONIX adapter configs
   docker exec onix-bap-plugin-rabbitmq ls -la /app/config/message-baised/rabbit-mq/onix-bap/
   ```

2. **Check config file syntax**:
   ```bash
   # View adapter configuration
   docker exec onix-bap-plugin-rabbitmq cat /app/config/message-baised/rabbit-mq/onix-bap/adapter.yaml
   ```

### RabbitMQ Connection Issues

1. **Verify RabbitMQ is running**:
   ```bash
   curl http://localhost:15672/api/overview
   ```

2. **Check queue bindings**:
   - Open RabbitMQ Management UI: `http://localhost:15672`
   - Navigate to "Exchanges" → `beckn_exchange`
   - Check "Bindings" to see queue bindings

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Main RabbitMQ README](../../../../docker/rabbitmq/README.md) - Detailed ONIX RabbitMQ adapter documentation

