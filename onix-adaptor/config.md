# Configuration Reference - REST API Adapter

This document describes the ONIX adapter configuration for REST API/HTTP-based deployments. The adapter uses standard HTTP handlers (`std` type) for both receiving and sending messages.

## Configuration Files

- **BAP Adapter**: `config/onix-bap/adapter.yaml`
- **BPP Adapter**: `config/onix-bpp/adapter.yaml`

---

## Application Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `appName` | `onix-ev-charging` (BAP) / `bpp-ev-charging` (BPP) | Application identifier for logging and identification |
| `log.level` | `debug` | Logging verbosity level (debug/info/warn/error) |
| `log.destinations[].type` | `stdout` | Log output destination |
| `log.contextKeys` | `transaction_id, message_id, subscriber_id, module_id` | Keys included in structured logs for tracing |

---

## HTTP Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `http.port` | `8001` (BAP) / `8002` (BPP) | HTTP server port for receiving requests |
| `http.timeout.read` | `30` | HTTP read timeout in seconds |
| `http.timeout.write` | `30` | HTTP write timeout in seconds |
| `http.timeout.idle` | `30` | HTTP idle connection timeout in seconds |

---

## Plugin Manager

| Key | Value | Description |
|-----|-------|-------------|
| `pluginManager.root` | `/app/plugins` | Root directory containing ONIX plugins |

---

## OpenTelemetry Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.otelsetup.id` | `otelsetup` | OpenTelemetry plugin identifier |
| `plugins.otelsetup.config.serviceName` | `beckn-onix` | Service name for telemetry |
| `plugins.otelsetup.config.serviceVersion` | `1.0.0` | Service version for telemetry |
| `plugins.otelsetup.config.enableMetrics` | `true` | Enable Prometheus metrics collection |
| `plugins.otelsetup.config.environment` | `development` | Environment name (development/staging/production) |
| `plugins.otelsetup.config.metricsPort` | `9003` (BAP) / `9004` (BPP) | Prometheus metrics endpoint port |

---

## Module: BAP Receiver (bapTxnReceiver)

Receives HTTP callbacks from CDS (Phase 1) and BPPs (Phase 2+). Uses standard HTTP handler.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bapTxnReceiver` | Module identifier |
| `modules[].path` | `/bap/receiver/` | HTTP endpoint path for receiving callbacks |
| `handler.type` | `std` | Standard HTTP handler type |
| `handler.role` | `bap` | Handler role (BAP) |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Registry Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.registry.id` | `registry` | Registry plugin identifier |
| `plugins.registry.config.url` | `http://mock-registry:3030` | Registry service URL for subscriber lookups |
| `plugins.registry.config.retry_max` | `3` | Maximum retry attempts for registry calls |
| `plugins.registry.config.retry_wait_min` | `100ms` | Minimum wait time between retries |
| `plugins.registry.config.retry_wait_max` | `500ms` | Maximum wait time between retries |

### Key Manager Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.keyManager.id` | `simplekeymanager` | Key manager plugin identifier |
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox1.com` | BAP subscriber ID |
| `plugins.keyManager.config.keyId` | `bap-key-1` | Key identifier for signing |
| `plugins.keyManager.config.signingPrivateKey` | `kaOxmZvVK0IdfMa+OtKZShKo9KVk4QLgCMn+Ch4QpU4=` | Private key for signing requests |
| `plugins.keyManager.config.signingPublicKey` | `ehNGIiQxbhAJGS9U7YZN5nsUNiLDlaSUQWlWbWc4SO4=` | Public key for signature verification |
| `plugins.keyManager.config.encrPrivateKey` | `kaOxmZvVK0IdfMa+OtKZShKo9KVk4QLgCMn+Ch4QpU4=` | Private key for encryption |
| `plugins.keyManager.config.encrPublicKey` | `ehNGIiQxbhAJGS9U7YZN5nsUNiLDlaSUQWlWbWc4SO4=` | Public key for decryption |

### Cache Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.cache.id` | `cache` | Cache plugin identifier |
| `plugins.cache.config.addr` | `redis-onix-bap:6379` | Redis server address for caching |

### Schema Validator Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.schemaValidator.id` | `schemav2validator` | Schema validator plugin identifier |
| `plugins.schemaValidator.config.type` | `url` | Schema source type (url/file) |
| `plugins.schemaValidator.config.location` | `https://raw.githubusercontent.com/beckn/protocol-specifications-v2/refs/heads/core-v2.0.0-rc/api/beckn.yaml` | Beckn protocol schema URL |
| `plugins.schemaValidator.config.cacheTTL` | `3600` | Schema cache duration in seconds |

### Signature Validator Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.signValidator.id` | `signvalidator` | Signature validator plugin identifier (receiver only) |

### Router Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.id` | `router` | Router plugin identifier |
| `plugins.router.config.routingConfig` | `/app/config/bap_receiver_routing.yaml` | Path to receiver routing rules file |

### Middleware

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.middleware[].id` | `reqpreprocessor` | Request preprocessor middleware |
| `plugins.middleware[].config.uuidKeys` | `transaction_id,message_id` | JSON keys to generate UUIDs for |
| `plugins.middleware[].config.role` | `bap` | Role for request preprocessing |

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSign` | Validate incoming message signature |
| `addRoute` | Apply routing rules to determine destination |
| `validateSchema` | Validate message against Beckn protocol schema |

---

## Module: BAP Caller (bapTxnCaller)

Entry point for all requests from BAP. Routes to CDS (Phase 1) or directly to BPP (Phase 2+). Uses standard HTTP handler.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bapTxnCaller` | Module identifier |
| `modules[].path` | `/bap/caller/` | HTTP endpoint path for sending requests |
| `handler.type` | `std` | Standard HTTP handler type |
| `handler.role` | `bap` | Handler role (BAP) |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Plugins

Same plugins as bapTxnReceiver (registry, keyManager, cache, schemaValidator) with the following differences:

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.config.routingConfig` | `/app/config/bap_caller_routing.yaml` | Path to caller routing rules file |
| `plugins.signer.id` | `signer` | Signer plugin identifier (caller only) |

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSchema` | Validate message against Beckn protocol schema |
| `addRoute` | Apply routing rules to determine destination |
| `sign` | Sign the message before sending |

---

## Module: BPP Receiver (bppTxnReceiver)

Receives HTTP requests from CDS (Phase 1) and BAP-ONIX (Phase 2+). Routes to backend via HTTP API.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bppTxnReceiver` | Module identifier |
| `modules[].path` | `/bpp/receiver/` | HTTP endpoint path for receiving requests |
| `handler.type` | `std` | Standard HTTP handler type |
| `handler.role` | `bpp` | Handler role (BPP) |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Key Manager Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `plugins.keyManager.config.keyId` | `bpp-key-1` | Key identifier for signing |
| `plugins.keyManager.config.signingPrivateKey` | `HH3KyEg4KhS8jVxPtEHMr6FTqyL0ef100vSPoZ2U0x4=` | Private key for signing |
| `plugins.keyManager.config.signingPublicKey` | `2ja8jS4O/HhyfnTzgC81mXkNNAueeqGEhv42FJtoUv8=` | Public key for verification |
| `plugins.keyManager.config.encrPrivateKey` | `HH3KyEg4KhS8jVxPtEHMr6FTqyL0ef100vSPoZ2U0x4=` | Private key for encryption |
| `plugins.keyManager.config.encrPublicKey` | `2ja8jS4O/HhyfnTzgC81mXkNNAueeqGEhv42FJtoUv8=` | Public key for decryption |

### Cache Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.cache.config.addr` | `redis-onix-bpp:6379` | Redis server address for caching |

### Router Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.config.routingConfig` | `/app/config/bpp_receiver_routing.yaml` | Path to receiver routing rules file |

### Middleware (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.middleware[].config.role` | `bpp` | Role for request preprocessing |

---

## Module: BPP Caller (bppTxnCaller)

Receives responses from backend via HTTP and sends HTTP to CDS (Phase 1) or BAP-ONIX (Phase 2+).

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bppTxnCaller` | Module identifier |
| `modules[].path` | `/bpp/caller/` | HTTP endpoint path for sending responses |
| `handler.type` | `std` | Standard HTTP handler type |
| `handler.role` | `bpp` | Handler role (BPP) |
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID (caller only) |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Router Plugin (BPP Caller)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.config.routingConfig` | `/app/config/bpp_caller_routing.yaml` | Path to caller routing rules file |

---

## Message Flow

### Phase 1: Discovery Flow
1. BAP Backend → HTTP POST to `/bap/caller/discover`
2. BAP Caller → Routes to Mock CDS via HTTP
3. Mock CDS → Broadcasts to all BPPs
4. BPP Receiver → Receives discover, routes to Mock BPP backend
5. Mock BPP → Sends on_discover response
6. BPP Caller → Routes to Mock CDS
7. Mock CDS → Aggregates and sends to BAP Receiver
8. BAP Receiver → Routes to BAP Backend

### Phase 2+: Transaction Flow
1. BAP Backend → HTTP POST to `/bap/caller/{action}` (select, init, confirm, etc.)
2. BAP Caller → Routes directly to BPP Receiver via HTTP (bypasses CDS)
3. BPP Receiver → Routes to Mock BPP backend
4. Mock BPP → Sends on_{action} response
5. BPP Caller → Routes directly to BAP Receiver via HTTP
6. BAP Receiver → Routes to BAP Backend

---

## Additional Notes

- All HTTP handlers use synchronous request/response pattern
- No message broker required - direct HTTP communication
- Routing rules determine destination based on action type and phase
- Signature validation occurs on receiver side
- Message signing occurs on caller side
- Schema validation ensures protocol compliance
