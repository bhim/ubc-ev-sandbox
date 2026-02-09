# Configuration Reference - Kafka Adapter

This document describes the ONIX adapter configuration for Kafka-based deployments. The adapter uses queue handlers for consuming messages from Kafka and standard HTTP handlers for receiving HTTP requests.

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

Receives HTTP requests from BPP-ONIX and publishes to BAP Backend via Kafka. Uses standard HTTP handler.

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

### Router Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.id` | `router` | Router plugin identifier |
| `plugins.router.config.routingConfig` | `/app/config/bapTxnReciever-routing.yaml` | Path to receiver routing rules file |

### Kafka Publisher Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.publisher.id` | `publisher` | Publisher plugin identifier |
| `plugins.publisher.config.type` | `kafka` | Publisher type (kafka) |
| `plugins.publisher.config.brokers` | `kafka:9092` | Kafka broker address |
| `plugins.publisher.config.topic` | `bap.on_default` | Default topic for publishing |
| `plugins.publisher.config.compressionCodec` | `snappy` | Compression codec (snappy/gzip/none) |
| `plugins.publisher.config.acks` | `all` | Acknowledgment mode (all/0/1) |
| `plugins.publisher.config.retries` | `2147483647` | Maximum retry attempts |
| `plugins.publisher.config.retryBackoffMs` | `100` | Retry backoff in milliseconds |
| `plugins.publisher.config.deliveryTimeoutMs` | `120000` | Delivery timeout in milliseconds |
| `plugins.publisher.config.enableIdempotence` | `true` | Enable idempotent producer |
| `plugins.publisher.config.admin.enabled` | `on` | Enable topic auto-creation |
| `plugins.publisher.config.admin.topicSpecs` | JSON array | Topic specifications for auto-creation (see below) |

**BAP Publisher Topics:**
- `bap.on_discover`, `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support`, `bap.on_default`

### Processing Steps

| Step | Description |
|------|-------------|
| `validateSchema` | Validate message against Beckn protocol schema |
| `addRoute` | Apply routing rules to determine destination |
| *(Note: validateSign is commented out in Kafka adapter)* | |

---

## Module: BAP Caller (bapTxnCaller)

Consumes requests from BAP Backend via Kafka and routes them outward. Uses queue handler.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bapTxnCaller` | Module identifier |
| `modules[].path` | `""` | Path not used for queue handlers |
| `handler.type` | `queue` | Queue handler type for Kafka consumption |
| `handler.role` | `bap` | Handler role (BAP) |
| `handler.subscriberId` | `ev-charging.sandbox1.com` | BAP subscriber ID |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Maximum idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Maximum idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |

### Kafka Consumer Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.consumer.id` | `consumer` | Consumer plugin identifier |
| `plugins.consumer.config.subscriberId` | `ev-charging.sandbox1.com` | Subscriber ID |
| `plugins.consumer.config.role` | `bap` | Consumer role |
| `plugins.consumer.config.consumerType` | `kafka` | Consumer type (kafka) |
| `plugins.consumer.config.consumerThreads` | `2` | Number of consumer threads |
| `plugins.consumer.config.consumer.id` | `kafkaconsumer` | Consumer identifier |
| `plugins.consumer.config.consumer.brokers` | `kafka:9092` | Kafka broker address |
| `plugins.consumer.config.consumer.topics` | `bap.discover,bap.select,bap.init,bap.confirm,bap.status,bap.track,bap.cancel,bap.update,bap.rating,bap.support` | Comma-separated list of topics to consume |
| `plugins.consumer.config.consumer.groupId` | `bap_caller_group` | Kafka consumer group ID |
| `plugins.consumer.config.consumer.autoCommit` | `false` | Disable auto-commit (manual commit) |
| `plugins.consumer.config.consumer.commitInterval` | `10s` | Commit interval for manual commits |
| `plugins.consumer.config.consumer.sessionTimeout` | `10s` | Session timeout |
| `plugins.consumer.config.consumer.heartbeatInterval` | `1s` | Heartbeat interval |
| `plugins.consumer.config.consumer.maxPollInterval` | `5m` | Maximum poll interval |
| `plugins.consumer.config.consumer.rebalanceTimeout` | `30s` | Rebalance timeout |
| `plugins.consumer.config.consumer.fetchMinBytes` | `1024` | Minimum bytes to fetch |
| `plugins.consumer.config.consumer.fetchMaxWaitTime` | `500ms` | Maximum wait time for fetch |
| `plugins.consumer.config.consumer.maxPartitionFetchBytes` | `131072` | Maximum bytes per partition |
| `plugins.consumer.config.consumer.maxRetry` | `3` | Maximum retry attempts |
| `plugins.consumer.config.consumer.useTLS` | `false` | Enable TLS for Kafka connection |
| `plugins.consumer.config.consumer.tlsInsecureSkipVerify` | `false` | Skip TLS certificate verification |
| `plugins.consumer.config.consumer.tlsCAFile` | `""` | TLS CA certificate file path |
| `plugins.consumer.config.consumer.tlsCertFile` | `""` | TLS certificate file path |
| `plugins.consumer.config.consumer.tlsKeyFile` | `""` | TLS key file path |
| `plugins.consumer.config.consumer.dialTimeout` | `5s` | Connection dial timeout |
| `plugins.consumer.config.consumer.admin.enabled` | `on` | Enable topic auto-creation |
| `plugins.consumer.config.consumer.admin.topicSpecs` | JSON array | Topic specifications for auto-creation |
| `plugins.consumer.config.steps` | `["addRoute", "validateSchema", "sign"]` | Processing steps for consumed messages |

**BAP Consumer Topics:**
- `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`

### Router Plugin

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.router.config.routingConfig` | `/app/config/bapTxnCaller-routing.yaml` | Path to caller routing rules file |

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

Receives HTTP requests from BAP-ONIX and publishes to BPP Backend via Kafka.

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

### Kafka Publisher Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.publisher.config.topic` | `bpp.default` | Default topic for publishing |
| `plugins.publisher.config.admin.topicSpecs` | JSON array | Topic specifications including: `bpp.discover`, `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support`, `bpp.default` |

---

## Module: BPP Caller (bppTxnCaller)

Consumes callbacks from BPP Backend via Kafka and routes them outward.

### Handler Configuration

| Key | Value | Description |
|-----|-------|-------------|
| `modules[].name` | `bppTxnCaller` | Module identifier |
| `modules[].path` | `""` | Path not used for queue handlers |
| `handler.type` | `queue` | Queue handler type for Kafka consumption |
| `handler.role` | `bpp` | Handler role (BPP) |
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID |

### Kafka Consumer Plugin (BPP)

| Key | Value | Description |
|-----|-------|-------------|
| `plugins.consumer.config.role` | `bpp` | Consumer role |
| `plugins.consumer.config.consumer.topics` | `bpp.on_discover,bpp.on_select,bpp.on_init,bpp.on_confirm,bpp.on_status,bpp.on_track,bpp.on_cancel,bpp.on_update,bpp.on_rating,bpp.on_support` | Comma-separated list of callback topics |
| `plugins.consumer.config.consumer.groupId` | `bpp_caller_group` | Kafka consumer group ID |
| `plugins.consumer.config.consumer.maxPollRecords` | `500` | Maximum records per poll |
| `plugins.consumer.config.consumer.startOffset` | `latest` | Start offset (latest/earliest) |
| `plugins.consumer.config.consumer.readBackoffMin` | `100ms` | Minimum read backoff |
| `plugins.consumer.config.consumer.readBackoffMax` | `1s` | Maximum read backoff |
| `plugins.consumer.config.consumer.admin.topicSpecs` | JSON array | Topic specifications for callback topics |

**BPP Consumer Topics:**
- `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`

---

## Message Flow

### Phase 1: Discovery Flow
1. BAP Backend → Publishes to Kafka topic `bap.discover`
2. BAP Caller → Consumes from `bap.discover`, routes to Mock CDS via HTTP
3. Mock CDS → Broadcasts to all BPPs
4. BPP Receiver → Receives discover, publishes to Kafka topic `bpp.discover`
5. Mock BPP Kafka → Consumes `bpp.discover`, processes, publishes `bpp.on_discover`
6. BPP Caller → Consumes `bpp.on_discover`, routes to Mock CDS via HTTP
7. Mock CDS → Aggregates and sends to BAP Receiver via HTTP
8. BAP Receiver → Publishes to Kafka topic `bap.on_discover`
9. BAP Backend → Consumes `bap.on_discover` callback

### Phase 2+: Transaction Flow
1. BAP Backend → Publishes to Kafka topic `bap.{action}`
2. BAP Caller → Consumes from `bap.{action}`, routes directly to BPP Receiver via HTTP
3. BPP Receiver → Publishes to Kafka topic `bpp.{action}`
4. Mock BPP Kafka → Consumes `bpp.{action}`, processes, publishes `bpp.on_{action}`
5. BPP Caller → Consumes `bpp.on_{action}`, routes directly to BAP Receiver via HTTP
6. BAP Receiver → Publishes to Kafka topic `bap.on_{action}`
7. BAP Backend → Consumes `bap.on_{action}` callback

---

## Additional Notes

- Kafka topics are auto-created when first message is published (if admin.enabled is "on")
- Consumer groups ensure message distribution across multiple instances
- Manual commit mode (`autoCommit: false`) provides better message delivery guarantees
- Publisher uses idempotent producer to prevent duplicate messages
- All topics use 1 partition and replication factor of 1 (suitable for development)
- Production deployments should configure appropriate partition counts and replication factors
