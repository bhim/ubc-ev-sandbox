# Microservice Architecture - API Integration

This guide demonstrates how to integrate the **onix-adapter** with BAP and BPP applications using **Docker containers** in a **microservice architecture** where each API endpoint routes to different mock BAP and BPP services through routing configurations.

## Architecture Overview

In this microservice architecture, a single adapter service handles all endpoints, but each endpoint is configured to route to different mock services. This allows for:
- **Centralized Management**: Single service to manage and monitor
- **Flexible Routing**: Each endpoint can route to different mock services for testing
- **Easy Configuration**: Routing changes only require updating YAML files
- **Resource Efficiency**: Single service instance handles all endpoints

### Components

- **Redis**: Shared caching service for each adapter
- **Onix-Adapter Services**: Single BAP and BPP service handling all endpoints
- **Mock Services**: Different mock BAP/BPP services for each endpoint (mock-bap-1 through mock-bap-10, mock-bpp-1 through mock-bpp-10)
- **Routing Configuration**: YAML files that define endpoint-to-mock-service routing

## Directory Structure

```
docker/api/microservice/
├── docker-compose-onix-bap-plugin.yml          # BAP service configuration
├── docker-compose-onix-bpp-plugin.yml          # BPP service configuration
├── config/
│   ├── onix-bap/
│   │   ├── adapter.yaml                        # BAP adapter configuration
│   │   ├── bap_caller_routing.yaml              # BAP caller routing rules (routes to different mock BPPs)
│   │   └── bap_receiver_routing.yaml            # BAP receiver routing rules (routes to different mock BAPs)
│   └── onix-bpp/
│       ├── adapter.yaml                        # BPP adapter configuration
│       ├── bpp_caller_routing.yaml              # BPP caller routing rules (routes to different mock BAPs)
│       └── bpp_receiver_routing.yaml            # BPP receiver routing rules (routes to different mock BPPs)
└── README.md
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Access to onix-adapter Docker images:
  - `manendrapalsingh/onix-bap-plugin:latest`
  - `manendrapalsingh/onix-bpp-plugin:latest`
- Schema files from `../../schemas` directory (read-only)
- Mock services configured (mock-bap-discover, mock-bap-select, mock-bap-init, etc., mock-bpp-discover, mock-bpp-select, mock-bpp-init, etc.)

## Service Ports

| Service | Container Name | HTTP Port | Redis Port | Redis Container |
|---------|---------------|-----------|------------|-----------------|
| BAP | onix-bap-plugin | 8001 | 6379 | redis-onix-bap |
| BPP | onix-bpp-plugin | 8002 | 6380 | redis-onix-bpp |

## Routing Configuration

### BAP Endpoint Routing

Each BAP endpoint routes to different mock services:

#### BAP Caller Routing (Outgoing Requests)

| Endpoint | Routes To |
|----------|-----------|
| discover | CDS (mock-cds:8082) |
| select | onix-bpp-plugin:8002/bpp/receiver/select → mock-bpp-select:9002 |
| init | onix-bpp-plugin:8002/bpp/receiver/init → mock-bpp-init:9002 |
| confirm | onix-bpp-plugin:8002/bpp/receiver/confirm → mock-bpp-confirm:9002 |
| update | onix-bpp-plugin:8002/bpp/receiver/update → mock-bpp-update:9002 |
| track | onix-bpp-plugin:8002/bpp/receiver/track → mock-bpp-track:9002 |
| cancel | onix-bpp-plugin:8002/bpp/receiver/cancel → mock-bpp-cancel:9002 |
| rating | onix-bpp-plugin:8002/bpp/receiver/rating → mock-bpp-rating:9002 |
| support | onix-bpp-plugin:8002/bpp/receiver/support → mock-bpp-support:9002 |

#### BAP Receiver Routing (Incoming Callbacks)

| Callback | Routes To |
|----------|-----------|
| on_discover | mock-bap-discover:9001 |
| on_select | mock-bap-select:9001 |
| on_init | mock-bap-init:9001 |
| on_confirm | mock-bap-confirm:9001 |
| on_status | mock-bap-status:9001 |
| on_track | mock-bap-track:9001 |
| on_cancel | mock-bap-cancel:9001 |
| on_update | mock-bap-update:9001 |
| on_rating | mock-bap-rating:9001 |
| on_support | mock-bap-support:9001 |

### BPP Endpoint Routing

Each BPP endpoint routes to different mock services:

#### BPP Caller Routing (Outgoing Responses)

| Response | Routes To |
|----------|-----------|
| on_discover | CDS (mock-cds:8082) |
| on_select | onix-bap-plugin:8001/bap/receiver/on_select → mock-bap-select:9001 |
| on_init | onix-bap-plugin:8001/bap/receiver/on_init → mock-bap-init:9001 |
| on_confirm | onix-bap-plugin:8001/bap/receiver/on_confirm → mock-bap-confirm:9001 |
| on_status | onix-bap-plugin:8001/bap/receiver/on_status → mock-bap-status:9001 |
| on_track | onix-bap-plugin:8001/bap/receiver/on_track → mock-bap-track:9001 |
| on_cancel | onix-bap-plugin:8001/bap/receiver/on_cancel → mock-bap-cancel:9001 |
| on_update | onix-bap-plugin:8001/bap/receiver/on_update → mock-bap-update:9001 |
| on_rating | onix-bap-plugin:8001/bap/receiver/on_rating → mock-bap-rating:9001 |
| on_support | onix-bap-plugin:8001/bap/receiver/on_support → mock-bap-support:9001 |

#### BPP Receiver Routing (Incoming Requests)

| Request | Routes To |
|---------|-----------|
| discover | mock-bpp-discover:9002 |
| select | mock-bpp-select:9002 |
| init | mock-bpp-init:9002 |
| confirm | mock-bpp-confirm:9002 |
| status | mock-bpp-status:9002 |
| track | mock-bpp-track:9002 |
| cancel | mock-bpp-cancel:9002 |
| update | mock-bpp-update:9002 |
| rating | mock-bpp-rating:9002 |
| support | mock-bpp-support:9002 |

## Quick Start

### Start BAP Service

```bash
docker-compose -f docker-compose-onix-bap-plugin.yml up -d
```

### Start BPP Service

```bash
docker-compose -f docker-compose-onix-bpp-plugin.yml up -d
```

### Start Both Services

```bash
docker-compose -f docker-compose-onix-bap-plugin.yml -f docker-compose-onix-bpp-plugin.yml up -d
```

### Verify Services

```bash
# Check running services
docker ps | grep -E "(onix-bap|onix-bpp|redis)"

# Check logs
docker-compose -f docker-compose-onix-bap-plugin.yml logs -f onix-bap-plugin
docker-compose -f docker-compose-onix-bpp-plugin.yml logs -f onix-bpp-plugin
```

## API Endpoints

### BAP Endpoints

All BAP endpoints are exposed through a single service:

| Endpoint | Caller URL | Receiver URL |
|----------|------------|--------------|
| discover | `http://localhost:8001/bap/caller/discover` | `http://localhost:8001/bap/receiver/on_discover` |
| select | `http://localhost:8001/bap/caller/select` | `http://localhost:8001/bap/receiver/on_select` |
| init | `http://localhost:8001/bap/caller/init` | `http://localhost:8001/bap/receiver/on_init` |
| confirm | `http://localhost:8001/bap/caller/confirm` | `http://localhost:8001/bap/receiver/on_confirm` |
| update | `http://localhost:8001/bap/caller/update` | `http://localhost:8001/bap/receiver/on_update` |
| track | `http://localhost:8001/bap/caller/track` | `http://localhost:8001/bap/receiver/on_track` |
| cancel | `http://localhost:8001/bap/caller/cancel` | `http://localhost:8001/bap/receiver/on_cancel` |
| rating | `http://localhost:8001/bap/caller/rating` | `http://localhost:8001/bap/receiver/on_rating` |
| support | `http://localhost:8001/bap/caller/support` | `http://localhost:8001/bap/receiver/on_support` |

### BPP Endpoints

All BPP endpoints are exposed through a single service:

| Endpoint | Caller URL | Receiver URL |
|----------|------------|--------------|
| on_discover | `http://localhost:8002/bpp/caller/on_discover` | `http://localhost:8002/bpp/receiver/discover` |
| on_select | `http://localhost:8002/bpp/caller/on_select` | `http://localhost:8002/bpp/receiver/select` |
| on_init | `http://localhost:8002/bpp/caller/on_init` | `http://localhost:8002/bpp/receiver/init` |
| on_confirm | `http://localhost:8002/bpp/caller/on_confirm` | `http://localhost:8002/bpp/receiver/confirm` |
| on_status | `http://localhost:8002/bpp/caller/on_status` | `http://localhost:8002/bpp/receiver/status` |
| on_track | `http://localhost:8002/bpp/caller/on_track` | `http://localhost:8002/bpp/receiver/track` |
| on_cancel | `http://localhost:8002/bpp/caller/on_cancel` | `http://localhost:8002/bpp/receiver/cancel` |
| on_update | `http://localhost:8002/bpp/caller/on_update` | `http://localhost:8002/bpp/receiver/update` |
| on_rating | `http://localhost:8002/bpp/caller/on_rating` | `http://localhost:8002/bpp/receiver/rating` |
| on_support | `http://localhost:8002/bpp/caller/on_support` | `http://localhost:8002/bpp/receiver/support` |

## Configuration Details

### Adapter Configuration

- **BAP**: `config/onix-bap/adapter.yaml`
- **BPP**: `config/onix-bpp/adapter.yaml`

Each adapter configuration defines:
- Application name and logging
- HTTP server settings
- Plugin configurations (registry, keyManager, cache, schemaValidator, etc.)
- Module definitions (caller and receiver)

### Routing Configuration

The routing configurations define how each endpoint routes to different mock services:

#### BAP Caller Routing (`config/onix-bap/bap_caller_routing.yaml`)
- Defines where outgoing requests from BAP are routed
- Each endpoint (select, init, confirm, etc.) routes to a different mock BPP service
- Discover endpoint routes to CDS for aggregation

#### BAP Receiver Routing (`config/onix-bap/bap_receiver_routing.yaml`)
- Defines where incoming callbacks to BAP are routed
- Each callback (on_select, on_init, etc.) routes to a different mock BAP service

#### BPP Caller Routing (`config/onix-bpp/bpp_caller_routing.yaml`)
- Defines where outgoing responses from BPP are routed
- Each response (on_select, on_init, etc.) routes to a different mock BAP service
- on_discover routes to CDS for aggregation

#### BPP Receiver Routing (`config/onix-bpp/bpp_receiver_routing.yaml`)
- Defines where incoming requests to BPP are routed
- Each request (select, init, etc.) routes to a different mock BPP service

## Mock Services Setup

To use this microservice architecture, you need to set up multiple mock services:

### Mock BAP Services

Create mock BAP services for each endpoint, each listening on port 9001 but with different container names:

```yaml
# Example: mock-bap-discover
services:
  mock-bap-discover:
    image: manendrapalsingh/mock-bap:latest
    container_name: mock-bap-discover
    ports:
      - "9001:9001"
    networks:
      - onix-network

# Example: mock-bap-select
  mock-bap-select:
    image: manendrapalsingh/mock-bap:latest
    container_name: mock-bap-select
    ports:
      - "9001:9001"
    networks:
      - onix-network

# ... and so on for: mock-bap-init, mock-bap-confirm, mock-bap-status, 
# mock-bap-track, mock-bap-cancel, mock-bap-update, mock-bap-rating, mock-bap-support
```

### Mock BPP Services

Create mock BPP services for each endpoint, each listening on port 9002 but with different container names:

```yaml
# Example: mock-bpp-discover
services:
  mock-bpp-discover:
    image: manendrapalsingh/mock-bpp:latest
    container_name: mock-bpp-discover
    ports:
      - "9002:9002"
    networks:
      - onix-network

# Example: mock-bpp-select
  mock-bpp-select:
    image: manendrapalsingh/mock-bpp:latest
    container_name: mock-bpp-select
    ports:
      - "9002:9002"
    networks:
      - onix-network

# ... and so on for: mock-bpp-init, mock-bpp-confirm, mock-bpp-status,
# mock-bpp-track, mock-bpp-cancel, mock-bpp-update, mock-bpp-rating, mock-bpp-support
```

## Stopping Services

```bash
# Stop BAP service
docker-compose -f docker-compose-onix-bap-plugin.yml down

# Stop BPP service
docker-compose -f docker-compose-onix-bpp-plugin.yml down

# Stop both services
docker-compose -f docker-compose-onix-bap-plugin.yml -f docker-compose-onix-bpp-plugin.yml down
```

## Example API Requests

### BAP - Discover Request

```bash
# Send a discover request from BAP
curl -X POST http://localhost:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "domain": "ev_charging_network",
      "version": "1.0.0",
      "action": "discover",
      "bap_id": "example-bap.com",
      "bap_uri": "http://mock-bap-discover:9001",
      "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
      "message_id": "550e8400-e29b-41d4-a716-446655440001",
      "timestamp": "2023-06-15T09:30:00.000Z",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "fulfillment": {
          "start": {
            "location": {
              "gps": "12.9715987,77.5945627"
            }
          },
          "end": {
            "location": {
              "gps": "12.9715987,77.5945627"
            }
          }
        }
      }
    }
  }'
```

### BAP - Select Request (Routes to mock-bpp-select)

```bash
# Send a select request - will route to mock-bpp-select service
curl -X POST http://localhost:8001/bap/caller/select \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "domain": "ev_charging_network",
      "version": "1.0.0",
      "action": "select",
      "bap_id": "example-bap.com",
      "bap_uri": "http://mock-bap-select:9001",
      "bpp_id": "example-bpp.com",
      "bpp_uri": "http://onix-bpp-plugin:8002",
      "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
      "message_id": "550e8400-e29b-41d4-a716-446655440002",
      "timestamp": "2023-06-15T09:30:00.000Z",
      "ttl": "PT30S"
    },
    "message": {
      "order": {
        "items": [
          {
            "id": "charging-station-1"
          }
        ]
      }
    }
  }'
```

**Note**: 
- In microservice architecture, each endpoint routes to different mock services
- The `bap_uri` should point to the specific mock BAP service for that callback (e.g., `mock-bap-select:9001` for on_select)
- The request will be routed through onix-bpp-plugin to the appropriate mock BPP service (e.g., `mock-bpp-select:9002`)

## Health Checks

### Check Service Health

```bash
# Check if BAP adapter is running
curl http://localhost:8001/health

# Check if BPP adapter is running
curl http://localhost:8002/health
```

### Verify Redis Connection

```bash
# Test BAP Redis connection
docker exec redis-onix-bap redis-cli ping
# Should return: PONG

# Test BPP Redis connection
docker exec redis-onix-bpp redis-cli ping
# Should return: PONG
```

### Verify Mock Services

```bash
# Check all mock BAP services
docker ps | grep mock-bap

# Check all mock BPP services
docker ps | grep mock-bpp

# Test connectivity to a specific mock service
docker exec onix-bap-plugin ping -c 3 mock-bap-select
docker exec onix-bap-plugin ping -c 3 mock-bpp-select
```

## Customization

### Changing Routing

To change which mock service an endpoint routes to, edit the respective routing YAML file:

1. **BAP Caller Routing**: Edit `config/onix-bap/bap_caller_routing.yaml`
   - Find the endpoint you want to change
   - Update the `url` field to point to the desired mock service

2. **BAP Receiver Routing**: Edit `config/onix-bap/bap_receiver_routing.yaml`
   - Find the callback you want to change
   - Update the `url` field to point to the desired mock service

3. **BPP Caller Routing**: Edit `config/onix-bpp/bpp_caller_routing.yaml`
   - Find the response you want to change
   - Update the `url` field to point to the desired mock service

4. **BPP Receiver Routing**: Edit `config/onix-bpp/bpp_receiver_routing.yaml`
   - Find the request you want to change
   - Update the `url` field to point to the desired mock service

After making changes, restart the service:
```bash
docker-compose -f docker-compose-onix-bap-plugin.yml restart
```

### Changing Ports

Edit the `ports` section in the respective `docker-compose-*.yml` file:

```yaml
ports:
  - "YOUR_PORT:8001"  # For BAP
  - "YOUR_PORT:8002"  # For BPP
```

## Troubleshooting

### Port Conflicts

If you encounter port conflicts, check which ports are in use:

```bash
# Check BAP port
lsof -i :8001

# Check BPP port
lsof -i :8002

# Check Redis ports
lsof -i :6379
lsof -i :6380
```

### Service Won't Start

1. **Check container logs:**
   ```bash
   docker-compose -f docker-compose-onix-bap-plugin.yml logs onix-bap-plugin
   ```

2. **Verify Redis is healthy:**
   ```bash
   docker exec redis-onix-bap redis-cli ping
   ```

3. **Check configuration files:**
   ```bash
   docker exec onix-bap-plugin ls -la /app/config/
   ```

### Routing Issues

1. **Verify mock services are running:**
   ```bash
   docker ps | grep mock-bap
   docker ps | grep mock-bpp
   # Should see services like: mock-bap-discover, mock-bap-select, mock-bpp-discover, etc.
   ```

2. **Check routing configuration:**
   ```bash
   docker exec onix-bap-plugin cat /app/config/onix-bap/bap_receiver_routing.yaml
   ```

3. **Test connectivity:**
   ```bash
   docker exec onix-bap-plugin ping -c 3 mock-bap-discover
   docker exec onix-bap-plugin ping -c 3 mock-bpp-select
   ```

## Benefits of This Architecture

1. **Simplicity**: Single service to manage instead of multiple services per endpoint
2. **Flexibility**: Easy to change routing by updating YAML files
3. **Testing**: Route different endpoints to different mock services for comprehensive testing
4. **Resource Efficiency**: Single service instance handles all endpoints
5. **Maintainability**: Centralized configuration makes it easier to manage and update

## Next Steps

- For RabbitMQ integration: See [RabbitMQ Integration](./../../rabbitmq/README.md)
- For Kafka integration: See [Kafka Integration](./../../kafka/README.md)
- For monolithic architecture: See [Monolithic API](./../monolithic/README.md)

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
