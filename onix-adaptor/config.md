# Configuration Reference - REST API Adapter

This document describes the ONIX adapter configuration for REST API/HTTP-based deployments. The adapter uses standard HTTP handlers (`std` type) for both receiving and sending messages.

## Configuration Files

- **BAP Adapter**: `config/onix-bap/adapter.yaml`
- **BPP Adapter**: `config/onix-bpp/adapter.yaml`
- **BAP Audit Fields**: `config/onix-bap/audit-fields.yaml`
- **BPP Audit Fields**: `config/onix-bpp/audit-fields.yaml`

---

## Application Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `appName` | `onix-ev-charging` (BAP) / `bpp-ev-charging` (BPP) | Application identifier for logging and identification |
| `log.level` | `debug` | Logging verbosity level (debug/info/warn/error) |
| `log.destinations[].type` | `stdout` | Log output destination |
| `log.contextKeys` | `transaction_id, message_id, subscriber_id, module_id, parent_id` | Keys included in structured logs for tracing |

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

## OpenTelemetry Plugin (OTLP)

Metrics, traces, and logs are sent via OTLP to the OTEL collector; no standalone metrics port is used.

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.otelsetup.id` | `otelsetup` | OpenTelemetry plugin identifier |
| `plugins.otelsetup.config.serviceName` | `onix-ev-charging-bap` (BAP) / `onix-ev-charging-bpp` (BPP) | Service name for telemetry |
| `plugins.otelsetup.config.serviceVersion` | `1.0.0` | Service version for telemetry |
| `plugins.otelsetup.config.environment` | `development` | Environment name (development/staging/production) |
| `plugins.otelsetup.config.domain` | `ev_charging` | Domain for telemetry classification |
| `plugins.otelsetup.config.otlpEndpoint` | `otel-collector-bap:4317` (BAP) / `otel-collector-bpp:4317` (BPP) | OTLP gRPC endpoint for the OTEL collector |
| `plugins.otelsetup.config.enableMetrics` | `true` | Enable metrics export |
| `plugins.otelsetup.config.networkMetricsGranularity` | `2min` | Granularity for network metrics |
| `plugins.otelsetup.config.networkMetricsFrequency` | `4min` | Frequency for network metrics aggregation |
| `plugins.otelsetup.config.enableTracing` | `true` | Enable trace export |
| `plugins.otelsetup.config.enableLogs` | `true` | Enable log export |
| `plugins.otelsetup.config.timeInterval` | `5` | Time interval (seconds) for periodic telemetry |
| `plugins.otelsetup.config.auditFieldsConfig` | `/app/config/audit-fields.yaml` | Path to PII/audit field masking config for logs and traces |

---

## Audit Fields (PII Masking)

The file referenced by `auditFieldsConfig` defines which fields are treated as PII and how they are masked in logs and traces.

### Config file

- **Path**: `config/onix-bap/audit-fields.yaml` (BAP) / `config/onix-bpp/audit-fields.yaml` (BPP)
- **Mounted in container**: `/app/config/audit-fields.yaml`

### Structure

| Section | Description |
|--------|-------------|
| `piiPatterns` | Named patterns (regex + mask type) for email, phone, tax_id, account, generic |
| `piiPaths` | JSON paths into the message (e.g. `message.order.beckn:buyer.beckn:email`) mapped to a pattern |

### Pattern types

- **replace**: Replace value with a fixed mask (e.g. `***@***.***` for email).
- **last4**: Show only last 4 characters.

### Example paths covered

- Buyer: email, telephone, displayName, taxID  
- Payment: paymentURL, txnRef, paidAt, settlement accounts (accountHolderName, accountNumber, vpa, paymentURL)  
- Fulfillment: address, streetAddress, extendedAddress, addressLocality, postalCode  
- Support: name, phone, email  
- Seller/provider: supportEmail, supportPhone, gstNumber  

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
| `handler.subscriberId` | `ev-charging.sandbox1.com` | BAP subscriber ID |
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
| `plugins.schemaValidator.config.extendedSchema_enabled` | `true` | Enable extended (domain) schema validation |
| `plugins.schemaValidator.config.extendedSchema_cacheTTL` | `3600` | Extended schema cache TTL in seconds |
| `plugins.schemaValidator.config.extendedSchema_maxCacheSize` | `100` | Max number of extended schemas to cache |
| `plugins.schemaValidator.config.extendedSchema_downloadTimeout` | `30` | Download timeout in seconds for extended schemas |
| `plugins.schemaValidator.config.extendedSchema_allowedDomains` | `beckn.org,example.com,raw.githubusercontent.com` | Allowed domains for extended schema URLs |

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
| `plugins.middleware[].config.contextKeys` | `transaction_id,message_id,parent_id` | JSON keys to propagate in context (e.g. for UUID generation/tracing) |
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
| `handler.subscriberId` | `ev-charging.sandbox1.com` | BAP subscriber ID |
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

### Middleware

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.middleware[].config.contextKeys` | `transaction_id,message_id,parent_id` | Context keys for preprocessing |
| `plugins.middleware[].config.role` | `bap` | Role for request preprocessing |

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
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Plugins

Same structure as BAP receiver: registry, keyManager, cache, schemaValidator (with extended schema options), signValidator, router, middleware. BPP-specific values:

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `plugins.keyManager.config.keyId` | `bpp-key-1` | Key identifier for signing |
| `plugins.keyManager.config.signingPrivateKey` | `HH3KyEg4KhS8jVxPtEHMr6FTqyL0ef100vSPoZ2U0x4=` | Private key for signing |
| `plugins.keyManager.config.signingPublicKey` | `2ja8jS4O/HhyfnTzgC81mXkNNAueeqGEhv42FJtoUv8=` | Public key for verification |
| `plugins.keyManager.config.encrPrivateKey` | `HH3KyEg4KhS8jVxPtEHMr6FTqyL0ef100vSPoZ2U0x4=` | Private key for encryption |
| `plugins.keyManager.config.encrPublicKey` | `2ja8jS4O/HhyfnTzgC81mXkNNAueeqGEhv42FJtoUv8=` | Public key for decryption |
| `plugins.cache.config.addr` | `redis-onix-bpp:6379` | Redis server address for caching |
| `plugins.router.config.routingConfig` | `/app/config/bpp_receiver_routing.yaml` | Path to receiver routing rules file |
| `plugins.middleware[].config.role` | `bpp` | Role for request preprocessing |
| `plugins.middleware[].config.contextKeys` | `transaction_id,message_id,parent_id` | Context keys for preprocessing |

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSign` | Validate incoming message signature |
| `addRoute` | Apply routing rules to determine destination |
| `validateSchema` | Validate message against Beckn protocol schema |

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
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Plugins

BPP Caller uses the same plugin set as BAP Caller: registry, keyManager, cache, schemaValidator (with extended schema options), router, signer, middleware. BPP-specific values:

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.config.routingConfig` | `/app/config/bpp_caller_routing.yaml` | Path to caller routing rules file |
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `plugins.cache.config.addr` | `redis-onix-bpp:6379` | Redis server address |
| `plugins.middleware[].config.contextKeys` | `transaction_id,message_id,parent_id` | Context keys for preprocessing |
| `plugins.middleware[].config.role` | `bpp` | Role for request preprocessing |

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSchema` | Validate message against Beckn protocol schema |
| `addRoute` | Apply routing rules to determine destination |
| `sign` | Sign the message before sending |

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

- All HTTP handlers use synchronous request/response pattern.
- No message broker required — direct HTTP communication.
- Routing rules determine destination based on action type and phase.
- Signature validation occurs on receiver side; message signing on caller side.
- Schema validation (core + optional extended/domain schemas) ensures protocol compliance.
- Telemetry (metrics, traces, logs) is sent via OTLP to the OTEL collector; PII is masked using `audit-fields.yaml`.
- Optional Dedi registry can be used by uncommenting the `dediregistry` block and commenting the default `registry` block in adapter YAML.
