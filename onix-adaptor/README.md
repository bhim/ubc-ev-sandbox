# ONIX Adapter – API Integration

This guide describes how to run the **onix-adapter** for BAP and BPP using **Docker Compose** with **REST API** communication. Each stack includes Redis, the adapter, and an OpenTelemetry collector.

## Architecture Overview

The adapter runs as a single container per side (BAP or BPP), handling both incoming and outgoing HTTP requests. Each compose file starts:

- **Redis** – caching and state
- **Onix adapter** – BAP or BPP HTTP endpoints
- **OTEL collector** – receives metrics, traces, and logs from the adapter via OTLP

All application communication is over HTTP/REST. Run from the **onix-adaptor/** directory so paths like `./config` and `./otel-config.yml` resolve correctly.

## Directory Structure

```
onix-adaptor/
├── docker-compose-onix-bap-plugin.yml   # BAP service configuration
├── docker-compose-onix-bpp-plugin.yml   # BPP service configuration
├── config/
│   ├── onix-bap/
│   │   ├── adapter.yaml                # BAP adapter configuration
│   │   ├── audit-fields.yaml           # PII masking for logs/traces (BAP)
│   │   ├── bap_caller_routing.yaml     # BAP caller routing rules
│   │   └── bap_receiver_routing.yaml   # BAP receiver routing rules
│   └── onix-bpp/
│       ├── adapter.yaml                # BPP adapter configuration
│       ├── audit-fields.yaml           # PII masking for logs/traces (BPP)
│       ├── bpp_caller_routing.yaml     # BPP caller routing rules
│       └── bpp_receiver_routing.yaml   # BPP receiver routing rules
├── otel-config.yml                     # OTEL collector config (used by both BAP and BPP compose)
├── config.md                           # Full configuration reference
└── README.md                           # This file
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Onix-adapter image: `manendrapalsingh/onix-adapter:v0.9.5` (same image for BAP and BPP)
- Schema files in `../schemas` (read-only). Ensure the parent of `onix-adaptor` contains a `schemas` directory.

## Quick Start

Run all commands from the **onix-adaptor/** directory.

### BAP (Buyer App Provider)

1. **Start the stack** (Redis + onix-bap-plugin + otel-collector-bap):
   ```bash
   cd onix-adaptor
   docker-compose -f docker-compose-onix-bap-plugin.yml up -d
   ```

2. **Verify containers:**
   ```bash
   docker ps | grep -E "(redis-onix-bap|onix-bap-plugin|otel-collector-bap)"
   ```

3. **Adapter endpoints:**
   - Caller: `http://localhost:8001/bap/caller/`
   - Receiver: `http://localhost:8001/bap/receiver/`

4. **Logs:**
   ```bash
   docker-compose -f docker-compose-onix-bap-plugin.yml logs -f onix-bap-plugin
   ```

### BPP (Buyer Platform Provider)

1. **Start the stack** (Redis + onix-bpp-plugin + otel-collector-bpp):
   ```bash
   cd onix-adaptor
   docker-compose -f docker-compose-onix-bpp-plugin.yml up -d
   ```

2. **Verify containers:**
   ```bash
   docker ps | grep -E "(redis-onix-bpp|onix-bpp-plugin|otel-collector-bpp)"
   ```

3. **Adapter endpoints:**
   - Caller: `http://localhost:8002/bpp/caller/`
   - Receiver: `http://localhost:8002/bpp/receiver/`

4. **Logs:**
   ```bash
   docker-compose -f docker-compose-onix-bpp-plugin.yml logs -f onix-bpp-plugin
   ```

## Configuration Details

For full configuration reference (all keys, plugins, OTLP, audit-fields), see [config.md](./config.md).

### BAP Configuration

#### Adapter Configuration (`config/onix-bap/adapter.yaml`)

- **Application**: `onix-ev-charging`
- **HTTP Port**: `8001`
- **Subscriber ID**: `ev-charging.sandbox1.com`
- **Modules**:
  - `bapTxnReceiver`: Receives callbacks from CDS (Phase 1) and BPPs (Phase 2+)
    - Path: `/bap/receiver/`
    - Handles: `on_discover`, `on_select`, `on_init`, `on_confirm`, etc.
  - `bapTxnCaller`: Entry point for requests from BAP application
    - Path: `/bap/caller/`
    - Handles: `discover`, `select`, `init`, `confirm`, etc.
- **OpenTelemetry**: OTLP endpoint `otel-collector-bap:4317`; metrics, traces, and logs with PII masking via `audit-fields.yaml`.

#### Routing Configuration

**BAP Caller Routing** (`bap_caller_routing.yaml`):
- Phase 1: `discover` → Routes to CDS for aggregation
- Phase 2+: Other actions (`select`, `init`, `confirm`, etc.) → Routes directly to BPP

**BAP Receiver Routing** (`bap_receiver_routing.yaml`):
- Phase 1: `on_discover` → Routes callbacks to BAP backend
- Phase 2+: Other callbacks → Routes to BAP backend

### BPP Configuration

#### Adapter Configuration (`config/onix-bpp/adapter.yaml`)

- **Application**: `bpp-ev-charging`
- **HTTP Port**: `8002`
- **Subscriber ID**: `ev-charging.sandbox2.com`
- **Modules**:
  - `bppTxnReceiver`: Receives requests from CDS (Phase 1) and BAP-ONIX (Phase 2+)
    - Path: `/bpp/receiver/`
    - Handles: `discover`, `select`, `init`, `confirm`, etc.
  - `bppTxnCaller`: Sends responses to CDS/BAP-ONIX
    - Path: `/bpp/caller/`
    - Handles: `on_discover`, `on_select`, `on_init`, `on_confirm`, etc.
- **OpenTelemetry**: OTLP endpoint `otel-collector-bpp:4317`; metrics, traces, and logs with PII masking via `audit-fields.yaml`.

#### Routing Configuration

**BPP Caller Routing** (`bpp_caller_routing.yaml`):
- Phase 1: `on_discover` → Routes to CDS for aggregation
- Phase 2+: Other responses → Routes directly to BAP-ONIX

**BPP Receiver Routing** (`bpp_receiver_routing.yaml`):
- Phase 1: `discover` → Routes to BPP backend service
- Phase 2+: Other requests → Routes to BPP backend service

### Audit Fields (PII Masking)

Each side has an `audit-fields.yaml` that defines which message fields are treated as PII and how they are masked in logs and traces (e.g. email, phone, address, payment details). See [config.md](./config.md#audit-fields-pii-masking) for structure and options.

## API Endpoints

### BAP Endpoints

| Endpoint | Purpose | Path |
|----------|---------|------|
| Caller | Send requests to BPP/CDS | `/bap/caller/{action}` |
| Receiver | Receive callbacks from BPP/CDS | `/bap/receiver/{action}` |

**Example:**
- Send discover request: `POST http://localhost:8001/bap/caller/discover`
- Receive callback: `POST http://localhost:8001/bap/receiver/on_discover`

### BPP Endpoints

| Endpoint | Purpose | Path |
|----------|---------|------|
| Caller | Send responses to BAP/CDS | `/bpp/caller/{action}` |
| Receiver | Receive requests from BAP/CDS | `/bpp/receiver/{action}` |

**Example:**
- Receive discover request: `POST http://localhost:8002/bpp/receiver/discover`
- Send response: `POST http://localhost:8002/bpp/caller/on_discover`

## Environment Variables

The adapter uses the following environment variables:

| Variable | Description |
|----------|-------------|
| `CONFIG_FILE` | Path to the adapter configuration file (default: `/app/config/adapter.yaml`) |
| `REDIS_PASSWORD` | Redis password; must match the Redis service (`your-redis-password` in compose) |
| `CONFIG_PATH` | Optional; base path for config. Default `./config` so BAP uses `./config/onix-bap`, BPP uses `./config/onix-bpp`. |

## Volume Mounts

Paths are relative to the **onix-adaptor/** directory.

| Mount (host) | Container | Service |
|--------------|-----------|---------|
| `${CONFIG_PATH:-./config}/onix-bap` or `onix-bpp` | `/app/config` | onix-bap-plugin / onix-bpp-plugin |
| `../schemas` | `/app/schemas:ro` | onix-bap-plugin / onix-bpp-plugin |
| `./otel-config.yml` | `/etc/otelcol/config.yaml:ro` | otel-collector-bap / otel-collector-bpp |

The adapter config directory provides `adapter.yaml`, `audit-fields.yaml`, and the routing YAML files. The OTEL collector uses the single `otel-config.yml` in this folder for both BAP and BPP stacks.

## Network Configuration

All services use the **onix-network** bridge:
- **BAP stack**: `redis-onix-bap`, `onix-bap-plugin`, `otel-collector-bap`
- **BPP stack**: `redis-onix-bpp`, `onix-bpp-plugin`, `otel-collector-bpp`

The adapter sends OTLP to its collector over this network (`otel-collector-bap:4317` or `otel-collector-bpp:4317`).

## Stopping Services

```bash
# Stop BAP services
docker-compose -f docker-compose-onix-bap-plugin.yml down

# Stop BPP services
docker-compose -f docker-compose-onix-bpp-plugin.yml down

# Stop both and remove volumes
docker-compose -f docker-compose-onix-bap-plugin.yml -f docker-compose-onix-bpp-plugin.yml down -v
```

## Troubleshooting

### Service Won't Start

1. **Check if ports are available:**
   ```bash
   # Check port 8001 (BAP)
   lsof -i :8001
   
   # Check port 8002 (BPP)
   lsof -i :8002
   
   # Check Redis ports
   lsof -i :6379  # BAP Redis
   lsof -i :6380  # BPP Redis
   ```

2. **Verify Docker image:**
   ```bash
   docker images | grep onix-adapter
   ```

3. **OTEL collector:** If the adapter fails to send telemetry, ensure the collector is up and using `./otel-config.yml`:
   ```bash
   docker-compose -f docker-compose-onix-bap-plugin.yml logs otel-collector-bap
   ```

4. **Check container logs:**
   ```bash
   docker-compose -f docker-compose-onix-bap-plugin.yml logs
   docker-compose -f docker-compose-onix-bpp-plugin.yml logs
   ```

### Configuration Issues

1. **Verify config files are mounted correctly:**
   ```bash
   docker exec onix-bap-plugin ls -la /app/config/
   docker exec onix-bpp-plugin ls -la /app/config/
   ```

2. **Check adapter configuration:**
   ```bash
   docker exec onix-bap-plugin cat /app/config/adapter.yaml
   ```

3. **OTEL collector config:** Ensure `otel-config.yml` exists in onix-adaptor and is mounted:
   ```bash
   docker exec otel-collector-bap cat /etc/otelcol/config.yaml | head -20
   ```

### Redis Connection Issues

1. **Verify Redis is healthy:**
   ```bash
   docker exec redis-onix-bap redis-cli -a your-redis-password ping
   docker exec redis-onix-bpp redis-cli -a your-redis-password ping
   ```

2. **Check Redis logs:**
   ```bash
   docker-compose -f docker-compose-onix-bap-plugin.yml logs redis-onix-bap
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
      "bap_uri": "http://your-bap-backend:9001",
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

### BAP - Select Request

```bash
# Send a select request
curl -X POST http://localhost:8001/bap/caller/select \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "domain": "ev_charging_network",
      "version": "1.0.0",
      "action": "select",
      "bap_id": "example-bap.com",
      "bap_uri": "http://your-bap-backend:9001",
      "bpp_id": "example-bpp.com",
      "bpp_uri": "http://your-bpp-backend:9002",
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
- Replace `your-bap-backend` and `your-bpp-backend` with your actual backend service hostnames
- The request will be automatically routed to CDS (for discover) or BPP (for other actions) based on the routing configuration
- Callbacks will be sent to the `bap_uri` specified in the context

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
# Test BAP Redis connection (password matches docker-compose: your-redis-password)
docker exec redis-onix-bap redis-cli -a your-redis-password ping
# Should return: PONG

# Test BPP Redis connection
docker exec redis-onix-bpp redis-cli -a your-redis-password ping
# Should return: PONG
```

## Customization

### Changing Ports

Edit `ports` in the relevant compose file:
- **BAP**: adapter `8001:8001`; collector `4317:4317`, `4318:4318`, etc.
- **BPP**: adapter `8002:8002`; collector `4321:4317`, `4322:4318`, etc. (different host ports to avoid clashes if both stacks run)

### Updating Configuration

1. **Adapter**: Edit files in `config/onix-bap/` or `config/onix-bpp/` (`adapter.yaml`, `audit-fields.yaml`, routing). See [config.md](./config.md).
2. **OTEL collector**: Edit `otel-config.yml` in this folder; both BAP and BPP stacks use it.
3. **Restart** after changes:
   ```bash
   docker-compose -f docker-compose-onix-bap-plugin.yml restart
   # or
   docker-compose -f docker-compose-onix-bpp-plugin.yml restart
   ```

### Using Custom Images

Update the `image` field in `docker-compose-onix-bap-plugin.yml` or `docker-compose-onix-bpp-plugin.yml`:

```yaml
image: your-registry/onix-adapter:your-tag
```

Both BAP and BPP use the same image (`manendrapalsingh/onix-adapter:v0.9.5`); only the mounted config differs.

## Next Steps

- **Full config reference**: [config.md](./config.md) — plugins, OTLP, audit-fields, schema validator, routing.
- **OTEL**: Collector config is `./otel-config.yml` in this folder. Run docker-compose from **onix-adaptor/** so that path resolves.

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)

