# Configuration Reference - RabbitMQ Adapter

This document describes the ONIX adapter configuration for RabbitMQ-based deployments. The adapter uses queue handlers for consuming messages from RabbitMQ and standard HTTP handlers for receiving HTTP requests.

## Configuration Files

- **BAP Adapter**: `config/onix-bap/adapter.yaml`
- **BPP Adapter**: `config/onix-bpp/adapter.yaml`

---

## Application Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `appName` | `onix-ev-charging` | Application identifier for logging and identification |
| `log.level` | `debug` | Logging verbosity level (debug/info/warn/error) |
| `log.destinations[].type` | `stdout` | Log output destination |
| `log.contextKeys` | `transaction_id, message_id, subscriber_id, module_id` | Keys included in structured logs for tracing |

---

## HTTP Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `http.port` | `8001` (BAP) / `8002` (BPP) | HTTP server port for bapTxnReceiver/bppTxnReceiver to receive HTTP requests |
| `http.timeout.read` | `30` | HTTP read timeout in seconds |
| `http.timeout.write` | `30` | HTTP write timeout in seconds |
| `http.timeout.idle` | `30` | HTTP idle connection timeout in seconds |

**Note**: HTTP configuration is required for receiver modules to receive HTTP requests from BPP-ONIX/BAP-ONIX plugins.

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

Receives HTTP requests from BPP-ONIX and publishes to BAP Backend via RabbitMQ. Uses standard HTTP handler.

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
| `plugins.keyManager.config.signingPrivateKey` | `xnKF3BIg3Ei+ZEvxBtK0Mm4GRG1Mr0+K9IrxT6CnHEE=` | Private key for signing requests |
| `plugins.keyManager.config.signingPublicKey` | `MKA6fln8vmU2Qn80Y7dLzagpaPNqQWOlvGglMo5s0IU=` | Public key for signature verification |
| `plugins.keyManager.config.encrPrivateKey` | `xnKF3BIg3Ei+ZEvxBtK0Mm4GRG1Mr0+K9IrxT6CnHEE=` | Private key for encryption |
| `plugins.keyManager.config.encrPublicKey` | `MKA6fln8vmU2Qn80Y7dLzagpaPNqQWOlvGglMo5s0IU=` | Public key for decryption |

### Cache Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.cache.id` | `cache` | Cache plugin identifier |
| `plugins.cache.config.addr` | `redis-bap:6379` | Redis server address for caching |

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
| `plugins.router.config.routingConfig` | `/app/config/bapTxnReciever-routing.yaml` | Path to receiver routing rules file |

### RabbitMQ Publisher Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.publisher.id` | `publisher` | Publisher plugin identifier |
| `plugins.publisher.config.addr` | `rabbitmq:5672` | RabbitMQ broker address (AMQP port) |
| `plugins.publisher.config.exchange` | `beckn_exchange` | Exchange name for publishing messages |
| `plugins.publisher.config.durable` | `true` | Exchange durability (survives broker restart) |
| `plugins.publisher.config.username` | `guest` | RabbitMQ username |
| `plugins.publisher.config.password` | `guest` | RabbitMQ password |

**Note**: Messages are published with routing keys determined by the routing configuration (e.g., `bap.on_discover`, `bap.on_select`, etc.).

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSign` | Validate incoming message signature |
| `validateSchema` | Validate message against Beckn protocol schema |
| `addRoute` | Apply routing rules to determine destination and routing key |

---

## Module: BAP Caller (bapTxnCaller)

Consumes requests from BAP Backend via RabbitMQ and routes them outward. Uses queue handler.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bapTxnCaller` | Module identifier |
| `modules[].path` | `""` | Path not used for queue handlers |
| `handler.type` | `queue` | Queue handler type for RabbitMQ consumption |
| `handler.role` | `bap` | Handler role (BAP) |
| `handler.subscriberId` | `ev-charging.sandbox1.com` | BAP subscriber ID |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### RabbitMQ Consumer Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.consumer.id` | `consumer` | Consumer plugin identifier |
| `plugins.consumer.config.subscriberId` | `ev-charging.sandbox1.com` | Subscriber ID |
| `plugins.consumer.config.role` | `bap` | Consumer role |
| `plugins.consumer.config.consumerType` | `rabbitmq` | Consumer type (rabbitmq) |
| `plugins.consumer.config.consumerThreads` | `2` | Number of consumer threads |
| `plugins.consumer.config.consumer.id` | `rabbitmqconsumer` | Consumer identifier |
| `plugins.consumer.config.consumer.addr` | `rabbitmq:5672` | RabbitMQ broker address (AMQP port) |
| `plugins.consumer.config.consumer.exchange` | `beckn_exchange` | Exchange name to bind queue to |
| `plugins.consumer.config.consumer.routingKeys` | `bap.discover,bap.select,bap.init,bap.confirm,bap.status,bap.track,bap.cancel,bap.update,bap.rating,bap.support` | Comma-separated list of routing keys to consume |
| `plugins.consumer.config.consumer.queueName` | `bap_caller_queue` | Queue name for consuming messages |
| `plugins.consumer.config.consumer.durable` | `true` | Queue durability (survives broker restart) |
| `plugins.consumer.config.consumer.autoDelete` | `false` | Auto-delete queue when no consumers |
| `plugins.consumer.config.consumer.exclusive` | `false` | Exclusive queue (only one consumer) |
| `plugins.consumer.config.consumer.noWait` | `false` | No-wait mode for queue declaration |
| `plugins.consumer.config.consumer.autoAck` | `false` | Manual acknowledgment mode |
| `plugins.consumer.config.consumer.prefetchCount` | `10` | Prefetch count (messages per consumer) |
| `plugins.consumer.config.consumer.maxRetry` | `3` | Maximum retry attempts |
| `plugins.consumer.config.consumer.queueArgs` | `""` | Additional queue arguments (JSON string) |
| `plugins.consumer.config.consumer.username` | `guest` | RabbitMQ username |
| `plugins.consumer.config.consumer.password` | `guest` | RabbitMQ password |
| `plugins.consumer.config.steps` | `["addRoute", "validateSchema", "sign"]` | Processing steps for consumed messages |

**BAP Consumer Routing Keys:**
- `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`

### Router Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.config.routingConfig` | `/app/config/bapTxnCaller-routing.yaml` | Path to caller routing rules file |

### RabbitMQ Publisher Plugin (BAP Caller)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.publisher.id` | `publisher` | Publisher plugin identifier |
| `plugins.publisher.config.addr` | `rabbitmq:5672` | RabbitMQ broker address |
| `plugins.publisher.config.exchange` | `beckn_exchange` | Exchange name for publishing |
| `plugins.publisher.config.durable` | `true` | Exchange durability |
| `plugins.publisher.config.username` | `guest` | RabbitMQ username |
| `plugins.publisher.config.password` | `guest` | RabbitMQ password |

**Note**: Publisher is used for publishing responses/callbacks if needed.

### Signer Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.signer.id` | `signer` | Signer plugin identifier (caller only) |

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSchema` | Validate message against Beckn protocol schema |
| `addRoute` | Apply routing rules to determine destination |
| `sign` | Sign the message before sending |

---

## Module: BPP Receiver (bppTxnReceiver)

Receives HTTP requests from BAP-ONIX and publishes to BPP Backend via RabbitMQ.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bppTxnReceiver` | Module identifier |
| `modules[].path` | `/bpp/receiver/` | HTTP endpoint path for receiving requests |
| `handler.type` | `std` | Standard HTTP handler type |
| `handler.role` | `bpp` | Handler role (BPP) |
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID |

### Key Manager Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `plugins.keyManager.config.keyId` | `bpp-key-1` | Key identifier for signing |

### Cache Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.cache.config.addr` | `redis-bpp:6379` | Redis server address for caching |

### RabbitMQ Publisher Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.publisher.config.addr` | `rabbitmq:5672` | RabbitMQ broker address |
| `plugins.publisher.config.exchange` | `beckn_exchange` | Exchange name for publishing |
| `plugins.publisher.config.durable` | `true` | Exchange durability |
| `plugins.publisher.config.username` | `guest` | RabbitMQ username |
| `plugins.publisher.config.password` | `guest` | RabbitMQ password |

**Note**: Messages are published with routing keys like `bpp.discover`, `bpp.select`, etc., based on the action type.

---

## Module: BPP Caller (bppTxnCaller)

Consumes callbacks from BPP Backend via RabbitMQ and routes them outward.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bppTxnCaller` | Module identifier |
| `modules[].path` | `""` | Path not used for queue handlers |
| `handler.type` | `queue` | Queue handler type for RabbitMQ consumption |
| `handler.role` | `bpp` | Handler role (BPP) |
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID |

### RabbitMQ Consumer Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.consumer.config.role` | `bpp` | Consumer role |
| `plugins.consumer.config.consumer.routingKeys` | `bpp.on_discover,bpp.on_select,bpp.on_init,bpp.on_confirm,bpp.on_status,bpp.on_track,bpp.on_cancel,bpp.on_update,bpp.on_rating,bpp.on_support,bpp.catalog_publish,bpp.on_catalog_publish` | Comma-separated list of routing keys for callbacks |
| `plugins.consumer.config.consumer.queueName` | `bpp_caller_queue` | Queue name for consuming callbacks |
| `plugins.consumer.config.consumer.durable` | `true` | Queue durability |
| `plugins.consumer.config.consumer.autoDelete` | `false` | Auto-delete queue when no consumers |
| `plugins.consumer.config.consumer.exclusive` | `false` | Exclusive queue |
| `plugins.consumer.config.consumer.noWait` | `false` | No-wait mode |
| `plugins.consumer.config.consumer.autoAck` | `false` | Manual acknowledgment mode |
| `plugins.consumer.config.consumer.prefetchCount` | `10` | Prefetch count |
| `plugins.consumer.config.consumer.maxRetry` | `3` | Maximum retry attempts |
| `plugins.consumer.config.consumer.username` | `guest` | RabbitMQ username |
| `plugins.consumer.config.consumer.password` | `guest` | RabbitMQ password |

**BPP Consumer Routing Keys:**
- `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`, `bpp.catalog_publish`, `bpp.on_catalog_publish`

### RabbitMQ Publisher Plugin (BPP Caller)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.publisher.config.addr` | `rabbitmq:5672` | RabbitMQ broker address |
| `plugins.publisher.config.exchange` | `beckn_exchange` | Exchange name for publishing |
| `plugins.publisher.config.durable` | `true` | Exchange durability |
| `plugins.publisher.config.username` | `guest` | RabbitMQ username |
| `plugins.publisher.config.password` | `guest` | RabbitMQ password |

---

## Message Flow

### Phase 1: Discovery Flow
1. BAP Backend → Publishes to RabbitMQ with routing key `bap.discover`
2. Message routed to `bap_caller_queue` (bound to `bap.*` routing keys)
3. BAP Caller → Consumes from `bap_caller_queue`, routes to Mock CDS via HTTP
4. Mock CDS → Broadcasts to all BPPs
5. BPP Receiver → Receives discover, publishes to RabbitMQ with routing key `bpp.discover`
6. Mock BPP RabbitMQ → Consumes `bpp.discover`, processes, publishes with routing key `bpp.on_discover`
7. Message routed to `bpp_caller_queue` (bound to `bpp.on_*` routing keys)
8. BPP Caller → Consumes from `bpp_caller_queue`, routes to Mock CDS via HTTP
9. Mock CDS → Aggregates and sends to BAP Receiver via HTTP
10. BAP Receiver → Publishes to RabbitMQ with routing key `bap.on_discover`
11. BAP Backend → Consumes `bap.on_discover` callback

### Phase 2+: Transaction Flow
1. BAP Backend → Publishes to RabbitMQ with routing key `bap.{action}`
2. Message routed to `bap_caller_queue`
3. BAP Caller → Consumes from `bap_caller_queue`, routes directly to BPP Receiver via HTTP
4. BPP Receiver → Publishes to RabbitMQ with routing key `bpp.{action}`
5. Mock BPP RabbitMQ → Consumes `bpp.{action}`, processes, publishes with routing key `bpp.on_{action}`
6. Message routed to `bpp_caller_queue`
7. BPP Caller → Consumes from `bpp_caller_queue`, routes directly to BAP Receiver via HTTP
8. BAP Receiver → Publishes to RabbitMQ with routing key `bap.on_{action}`
9. BAP Backend → Consumes `bap.on_{action}` callback

---

## Exchange and Queue Configuration

### Exchange
- **Name**: `beckn_exchange`
- **Type**: Topic exchange (allows routing based on routing keys)
- **Durable**: `true` (survives broker restart)

### BAP Queues
- **Queue Name**: `bap_caller_queue`
- **Routing Keys**: `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
- **Durable**: `true`
- **Auto-Delete**: `false`
- **Exclusive**: `false`

### BPP Queues
- **Queue Name**: `bpp_caller_queue`
- **Routing Keys**: `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`, `bpp.catalog_publish`, `bpp.on_catalog_publish`
- **Durable**: `true`
- **Auto-Delete**: `false`
- **Exclusive**: `false`

---

## Additional Notes

- Exchange and queues must be pre-configured or created via setup scripts before adapter starts
- Manual acknowledgment mode (`autoAck: false`) provides better message delivery guarantees
- Prefetch count limits the number of unacknowledged messages per consumer
- Routing keys determine which queue receives which messages
- Topic exchange allows flexible routing based on routing key patterns
- Production deployments should use secure credentials instead of `guest/guest`
- Queue durability ensures messages survive broker restarts
