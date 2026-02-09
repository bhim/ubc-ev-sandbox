# Configuration Reference

Key-value pairs for BAP and BPP ONIX adapters.

---

## ONIX BAP Adapter (`onix-adaptor/config/onix-bap/adapter.yaml`)

| Key | Value | Use Case |
|-----|-------|----------|
| `appName` | `onix-ev-charging` | Application identifier for logging |
| `log.level` | `debug` | Logging verbosity (debug/info/warn/error) |
| `log.destinations[].type` | `stdout` | Where logs are written |
| `log.contextKeys` | `transaction_id, message_id, subscriber_id, module_id` | Keys included in structured logs |
| `http.port` | `8001` | Port BAP adapter listens on |
| `http.timeout.read` | `30` | HTTP read timeout in seconds |
| `http.timeout.write` | `30` | HTTP write timeout in seconds |
| `http.timeout.idle` | `30` | HTTP idle timeout in seconds |
| `pluginManager.root` | `/app/plugins` | Directory containing plugins |
| `plugins.otelsetup.config.serviceName` | `beckn-onix` | OpenTelemetry service name |
| `plugins.otelsetup.config.serviceVersion` | `1.0.0` | Service version for telemetry |
| `plugins.otelsetup.config.enableMetrics` | `true` | Enable Prometheus metrics |
| `plugins.otelsetup.config.environment` | `development` | Environment name |
| `plugins.otelsetup.config.metricsPort` | `9003` | Prometheus metrics endpoint port |
| `modules[].name` | `bapTxnReceiver` | Module for receiving callbacks |
| `modules[].path` | `/bap/receiver/` | HTTP endpoint path for receiver |
| `modules[].name` | `bapTxnCaller` | Module for sending requests |
| `modules[].path` | `/bap/caller/` | HTTP endpoint path for caller |
| `handler.type` | `std` | Standard handler type |
| `handler.role` | `bap` | Handler role (BAP) |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Max idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Max idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |
| `plugins.registry.id` | `registry` | Registry plugin identifier |
| `plugins.registry.config.url` | `http://mock-registry:3030` | Registry service URL for lookups |
| `plugins.registry.config.retry_max` | `3` | Max retry attempts for registry |
| `plugins.registry.config.retry_wait_min` | `100ms` | Min wait between retries |
| `plugins.registry.config.retry_wait_max` | `500ms` | Max wait between retries |
| `plugins.keyManager.id` | `simplekeymanager` | Key manager plugin identifier |
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox1.com` | BAP subscriber ID |
| `plugins.keyManager.config.keyId` | `bap-key-1` | Key identifier for signing |
| `plugins.keyManager.config.signingPrivateKey` | `kaOxmZvVK0IdfMa+OtKZShKo9KVk4QLgCMn+Ch4QpU4=` | Private key for signing requests |
| `plugins.keyManager.config.signingPublicKey` | `ehNGIiQxbhAJGS9U7YZN5nsUNiLDlaSUQWlWbWc4SO4=` | Public key for verification |
| `plugins.keyManager.config.encrPrivateKey` | `kaOxmZvVK0IdfMa+OtKZShKo9KVk4QLgCMn+Ch4QpU4=` | Private key for encryption |
| `plugins.keyManager.config.encrPublicKey` | `ehNGIiQxbhAJGS9U7YZN5nsUNiLDlaSUQWlWbWc4SO4=` | Public key for encryption |
| `plugins.cache.id` | `cache` | Cache plugin identifier |
| `plugins.cache.config.addr` | `redis.example.com:6380` | Redis address for caching |
| `plugins.cache.config.use_tls` | `true` | Enable TLS for Redis connection |
| `plugins.schemaValidator.id` | `schemav2validator` | Schema validator plugin identifier |
| `plugins.schemaValidator.config.type` | `url` | Schema source type |
| `plugins.schemaValidator.config.location` | `https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/api/beckn.yaml` | Beckn schema URL |
| `plugins.schemaValidator.config.cacheTTL` | `3600` | Schema cache duration in seconds |
| `plugins.signValidator.id` | `signvalidator` | Signature validator plugin (receiver only) |
| `plugins.signer.id` | `signer` | Signer plugin (caller only) |
| `plugins.router.id` | `router` | Router plugin identifier |
| `plugins.router.config.routingConfig` | `/app/config/bap_receiver_routing.yaml` | Path to receiver routing rules |
| `plugins.router.config.routingConfig` | `/app/config/bap_caller_routing.yaml` | Path to caller routing rules |
| `plugins.middleware[].id` | `reqpreprocessor` | Request preprocessor middleware |
| `plugins.middleware[].config.uuidKeys` | `transaction_id,message_id` | Keys to generate UUIDs for |
| `plugins.middleware[].config.role` | `bap` | Role for request preprocessing |
| `handler.steps` (receiver) | `validateSign, addRoute, validateSchema` | Processing pipeline for receiver |
| `handler.steps` (caller) | `validateSchema, addRoute, sign` | Processing pipeline for caller |

---

## BAP Routing

### Caller Routing (`onix-adaptor/config/onix-bap/bap_caller_routing.yaml`)

| Key | Value | Use Case |
|-----|-------|----------|
| `routingRules[].domain` | `beckn.one:deg:ev-charging` | Domain to match |
| `routingRules[].version` | `2.0.0` | Protocol version to match |
| `routingRules[].targetType` | `url` | Route to fixed URL (for discover) |
| `routingRules[].target.url` | `http://mock-cds:8082/csd` | CDS endpoint for discover |
| `routingRules[].target.excludeAction` | `false` | Include action in URL path |
| `routingRules[].endpoints` | `discover` | Phase 1 endpoint via CDS |
| `routingRules[].targetType` | `bpp` | Route using `bpp_uri` from context |
| `routingRules[].endpoints` | `select, init, confirm, status, track, cancel, update, rating, support` | Phase 2+ endpoints direct to BPP |

### Receiver Routing (`onix-adaptor/config/onix-bap/bap_receiver_routing.yaml`)

| Key | Value | Use Case |
|-----|-------|----------|
| `routingRules[].domain` | `beckn.one:deg:ev-charging` | Domain to match |
| `routingRules[].version` | `2.0.0` | Protocol version to match |
| `routingRules[].targetType` | `url` | Route to fixed URL |
| `routingRules[].target.url` | `http://mock-bap:9001` | Mock BAP for testing callbacks |
| `routingRules[].target.excludeAction` | `false` | Include action in URL path |
| `routingRules[].endpoints` | `on_discover, on_select, on_init, on_confirm, on_status, on_track, on_cancel, on_update, on_rating, on_support` | All callback endpoints |

---

## ONIX BPP Adapter (`onix-adaptor/config/onix-bpp/adapter.yaml`)

| Key | Value | Use Case |
|-----|-------|----------|
| `appName` | `bpp-ev-charging` | Application identifier for logging |
| `log.level` | `debug` | Logging verbosity (debug/info/warn/error) |
| `log.destinations[].type` | `stdout` | Where logs are written |
| `log.contextKeys` | `transaction_id, message_id, subscriber_id, module_id` | Keys included in structured logs |
| `http.port` | `8002` | Port BPP adapter listens on |
| `http.timeout.read` | `30` | HTTP read timeout in seconds |
| `http.timeout.write` | `30` | HTTP write timeout in seconds |
| `http.timeout.idle` | `30` | HTTP idle timeout in seconds |
| `pluginManager.root` | `/app/plugins` | Directory containing plugins |
| `plugins.otelsetup.config.serviceName` | `beckn-onix` | OpenTelemetry service name |
| `plugins.otelsetup.config.serviceVersion` | `1.0.0` | Service version for telemetry |
| `plugins.otelsetup.config.enableMetrics` | `true` | Enable Prometheus metrics |
| `plugins.otelsetup.config.environment` | `development` | Environment name |
| `plugins.otelsetup.config.metricsPort` | `9004` | Prometheus metrics endpoint port |
| `modules[].name` | `bppTxnReceiver` | Module for receiving requests |
| `modules[].path` | `/bpp/receiver/` | HTTP endpoint path for receiver |
| `modules[].name` | `bppTxnCaller` | Module for sending callbacks |
| `modules[].path` | `/bpp/caller/` | HTTP endpoint path for caller |
| `handler.type` | `std` | Standard handler type |
| `handler.role` | `bpp` | Handler role (BPP) |
| `handler.subscriberId` | `ev-charging.sandbox2.com` | BPP subscriber ID (caller only) |
| `handler.httpClientConfig.maxIdleConns` | `1000` | Max idle HTTP connections |
| `handler.httpClientConfig.maxIdleConnsPerHost` | `200` | Max idle connections per host |
| `handler.httpClientConfig.idleConnTimeout` | `300s` | Idle connection timeout |
| `handler.httpClientConfig.responseHeaderTimeout` | `5s` | Response header timeout |
| `plugins.registry.id` | `registry` | Registry plugin identifier |
| `plugins.registry.config.url` | `http://mock-registry:3030` | Registry service URL for lookups |
| `plugins.registry.config.retry_max` | `3` | Max retry attempts for registry |
| `plugins.registry.config.retry_wait_min` | `100ms` | Min wait between retries |
| `plugins.registry.config.retry_wait_max` | `500ms` | Max wait between retries |
| `plugins.keyManager.id` | `simplekeymanager` | Key manager plugin identifier |
| `plugins.keyManager.config.networkParticipant` | `ev-charging.sandbox2.com` | BPP subscriber ID |
| `plugins.keyManager.config.keyId` | `bpp-key-1` | Key identifier for signing |
| `plugins.keyManager.config.signingPrivateKey` | `HH3KyEg4KhS8jVxPtEHMr6FTqyL0ef100vSPoZ2U0x4=` | Private key for signing |
| `plugins.keyManager.config.signingPublicKey` | `2ja8jS4O/HhyfnTzgC81mXkNNAueeqGEhv42FJtoUv8=` | Public key for verification |
| `plugins.keyManager.config.encrPrivateKey` | `HH3KyEg4KhS8jVxPtEHMr6FTqyL0ef100vSPoZ2U0x4=` | Private key for encryption |
| `plugins.keyManager.config.encrPublicKey` | `2ja8jS4O/HhyfnTzgC81mXkNNAueeqGEhv42FJtoUv8=` | Public key for encryption |
| `plugins.cache.id` | `cache` | Cache plugin identifier |
| `plugins.cache.config.addr` | `redis.example.com:6380` | Redis address for caching |
| `plugins.cache.config.use_tls` | `true` | Enable TLS for Redis connection |
| `plugins.schemaValidator.id` | `schemav2validator` | Schema validator plugin identifier |
| `plugins.schemaValidator.config.type` | `url` | Schema source type |
| `plugins.schemaValidator.config.location` | `https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/api/beckn.yaml` | Beckn schema URL |
| `plugins.schemaValidator.config.cacheTTL` | `3600` | Schema cache duration in seconds |
| `plugins.signValidator.id` | `signvalidator` | Signature validator plugin (receiver only) |
| `plugins.signer.id` | `signer` | Signer plugin (caller only) |
| `plugins.router.id` | `router` | Router plugin identifier |
| `plugins.router.config.routingConfig` | `/app/config/bpp_receiver_routing.yaml` | Path to receiver routing rules |
| `plugins.router.config.routingConfig` | `/app/config/bpp_caller_routing.yaml` | Path to caller routing rules |
| `plugins.middleware[].id` | `reqpreprocessor` | Request preprocessor middleware |
| `plugins.middleware[].config.uuidKeys` | `transaction_id,message_id` | Keys to generate UUIDs for |
| `plugins.middleware[].config.role` | `bpp` | Role for request preprocessing |
| `handler.steps` (receiver) | `validateSign, addRoute, validateSchema` | Processing pipeline for receiver |
| `handler.steps` (caller) | `validateSchema, addRoute, sign` | Processing pipeline for caller |

---

## BPP Routing

### Receiver Routing (`onix-adaptor/config/onix-bpp/bpp_receiver_routing.yaml`)

| Key | Value | Use Case |
|-----|-------|----------|
| `routingRules[].domain` | `beckn.one:deg:ev-charging` | Domain to match |
| `routingRules[].version` | `2.0.0` | Protocol version to match |
| `routingRules[].targetType` | `url` | Route to fixed URL |
| `routingRules[].target.url` | `http://mock-bpp:9002` | Mock BPP backend service |
| `routingRules[].target.excludeAction` | `false` | Include action in URL path |
| `routingRules[].endpoints` | `discover, select, init, confirm, status, track, cancel, update, rating, support` | All action endpoints |

### Caller Routing (`onix-adaptor/config/onix-bpp/bpp_caller_routing.yaml`)

| Key | Value | Use Case |
|-----|-------|----------|
| `routingRules[].domain` | `beckn.one:deg:ev-charging` | Domain to match |
| `routingRules[].version` | `2.0.0` | Protocol version to match |
| `routingRules[].targetType` | `url` | Route to fixed URL (for on_discover) |
| `routingRules[].target.url` | `http://mock-cds:8082/csd` | CDS endpoint for on_discover |
| `routingRules[].target.excludeAction` | `false` | Include action in URL path |
| `routingRules[].endpoints` | `on_discover` | Phase 1 callback via CDS |
| `routingRules[].targetType` | `bap` | Route using `bap_uri` from context |
| `routingRules[].endpoints` | `on_select, on_init, on_confirm, on_status, on_track, on_cancel, on_update, on_rating, on_support` | Phase 2+ callbacks direct to BAP |

---

## Kubernetes Service Names

### Helm Deployments (with `fullnameOverride=onix`)

| Service Type | Service Name | Port | Description |
|--------------|--------------|------|-------------|
| **ONIX BAP Adapter** | `onix-bap-service` | 8001 | BAP adapter HTTP service |
| **ONIX BPP Adapter** | `onix-bpp-service` | 8002 | BPP adapter HTTP service |
| **Kafka Broker** | `onix-kafka` | 9092 | Kafka broker (shared by BAP and BPP) |
| **Kafka UI** | `onix-kafka-ui` | 8080 | Kafka Management UI (shared by BAP and BPP) |
| **RabbitMQ** | `onix-rabbitmq` | 5672, 15672 | RabbitMQ broker and Management UI |
| **Redis BAP** | `onix-bap-redis-bap` | 6379 | Redis cache for BAP adapter |
| **Redis BPP** | `onix-bpp-redis-bpp` | 6379 | Redis cache for BPP adapter |
| **Mock Registry** | `mock-registry` | 3030 | Registry service |
| **Mock CDS** | `mock-cds` | 8082 | Catalog Discovery Service |
| **Mock BAP** | `mock-bap` | 9001 | Mock BAP backend (REST) |
| **Mock BPP** | `mock-bpp` | 9002 | Mock BPP backend (REST) |

### Service Access Patterns

**Internal (ClusterIP):**
- BAP: `http://onix-bap-service:8001`
- BPP: `http://onix-bpp-service:8002`
- Kafka: `onix-kafka:9092`
- RabbitMQ: `onix-rabbitmq:5672` (AMQP), `onix-rabbitmq:15672` (Management API)

**External (Port Forward):**
```bash
# BAP and BPP services
kubectl port-forward svc/onix-bap-service 8001:8001 -n ev-charging-sandbox
kubectl port-forward svc/onix-bpp-service 8002:8002 -n ev-charging-sandbox

# Kafka UI
kubectl port-forward svc/onix-kafka-ui 8080:8080 -n ev-charging-sandbox

# RabbitMQ Management UI
kubectl port-forward svc/onix-rabbitmq 15672:15672 -n ev-charging-sandbox
```

---

## Directory Structure and Path References

### Correct Directory Paths

| Purpose | Correct Path | Incorrect Path (Fixed) |
|---------|--------------|----------------------|
| **Helm Kafka Sandbox Messages** | `helm-sandbox-kafka/message/` | ~~`sandbox/helm/kafka/message/`~~ |
| **Docker Kafka Sandbox Messages** | `sandbox-kafka/message/` | ~~`sandbox/docker/kafka/message/`~~ |
| **Helm RabbitMQ Sandbox Messages** | `helm-sandbox-rabbitMq/message/` | N/A (was incorrectly using Kafka terminology) |
| **Docker RabbitMQ Sandbox Messages** | `sandbox-rabbitMQ/message/` | ~~`sandbox/docker/monolithic/rabbitmq/message/`~~ |
| **Helm REST API Sandbox Messages** | `helm-sendbox/message/` | N/A |
| **Docker REST API Sandbox** | `sandbox/` | N/A |

### Message Testing Script Paths

**Kafka (Helm):**
```bash
cd helm-sandbox-kafka/message/bap/test && ./publish-all.sh
cd helm-sandbox-kafka/message/bpp/test && ./publish-all.sh
```

**Kafka (Docker):**
```bash
cd sandbox-kafka/message/bap/test && ./publish-all.sh
cd sandbox-kafka/message/bpp/test && ./publish-all.sh
```

**RabbitMQ (Helm):**
```bash
cd helm-sandbox-rabbitMq/message/bap/test && ./publish-all.sh
cd helm-sandbox-rabbitMq/message/bpp/test && ./publish-all.sh
```

**RabbitMQ (Docker):**
```bash
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh
```

**REST API (Helm):**
```bash
cd helm-sendbox/message/bap/test && ./test-all.sh
cd helm-sendbox/message/bpp/test && ./test-all.sh
```

---

## Technology-Specific Configurations

### Kafka Configuration

**Message Transport:**
- Uses Kafka topics for asynchronous messaging
- Topics follow pattern: `{component}.{action}` (e.g., `bap.discover`, `bpp.on_select`)
- Consumer groups managed by ONIX plugins

**Environment Variables:**
```bash
export KAFKA_HOST=localhost             # For local Kafka CLI tools
export KAFKA_PORT=9092                  # Kafka broker port
export KAFKA_BOOTSTRAP=localhost:9092   # Bootstrap server
export KAFKA_NAMESPACE=ev-charging-sandbox  # Kubernetes namespace
```

**Service Configuration:**
- Kafka broker: `onix-kafka:9092` (when `fullnameOverride=onix`)
- Kafka UI: `onix-kafka-ui:8080` (when `fullnameOverride=onix`)
- Topics are auto-created on first message publish

### RabbitMQ Configuration

**Message Transport:**
- Uses RabbitMQ queues with routing keys for asynchronous messaging
- Exchange: `beckn_exchange` (topic exchange)
- Queues: `bap_caller_queue`, `bpp_caller_queue`
- Routing keys follow pattern: `{component}.{action}` (e.g., `bap.discover`, `bpp.on_select`)

**Environment Variables:**
```bash
export RABBITMQ_HOST=localhost          # RabbitMQ host
export RABBITMQ_PORT=15672             # Management API port
export RABBITMQ_USER=guest             # Management API username
export RABBITMQ_PASS=guest             # Management API password
export EXCHANGE=beckn_exchange         # Exchange name
export RABBITMQ_NAMESPACE=ev-charging-sandbox  # Kubernetes namespace
```

**Service Configuration:**
- RabbitMQ broker: `onix-rabbitmq:5672` (AMQP port)
- RabbitMQ Management: `onix-rabbitmq:15672` (Management API port)
- Exchange and queues must be pre-configured or created via setup scripts

**Queue Bindings:**
- `bap_caller_queue` bound to `beckn_exchange` with routing keys `bap.*`
- `bpp_caller_queue` bound to `beckn_exchange` with routing keys `bpp.on_*` and `bpp.catalog_publish`

### REST API Configuration

**Message Transport:**
- Uses synchronous HTTP/REST endpoints
- Direct HTTP calls between services
- No message broker required

**Service Endpoints:**
- BAP Caller: `http://onix-bap-service:8001/bap/caller/{action}`
- BAP Receiver: `http://onix-bap-service:8001/bap/receiver/{action}`
- BPP Caller: `http://onix-bpp-service:8002/bpp/caller/{action}`
- BPP Receiver: `http://onix-bpp-service:8002/bpp/receiver/{action}`

---

## Configuration File Locations

### ONIX Adapter Configurations

| Component | Configuration Path | Description |
|-----------|-------------------|-------------|
| **BAP (REST)** | `onix-adaptor/config/onix-bap/` | REST API adapter configuration |
| **BPP (REST)** | `onix-adaptor/config/onix-bpp/` | REST API adapter configuration |
| **BAP (Kafka)** | `onix-adaptor-kafka/config/onix-bap/` | Kafka adapter configuration |
| **BPP (Kafka)** | `onix-adaptor-kafka/config/onix-bpp/` | Kafka adapter configuration |
| **BAP (RabbitMQ)** | `onix-adaptor-rabbitMQ/config/onix-bap/` | RabbitMQ adapter configuration |
| **BPP (RabbitMQ)** | `onix-adaptor-rabbitMQ/config/onix-bpp/` | RabbitMQ adapter configuration |

### Helm Chart Configurations

| Chart | Values File | Description |
|-------|-------------|-------------|
| **REST API** | `helm/values.yaml`, `helm/values-bap.yaml`, `helm/values-bpp.yaml` | REST API Helm chart values |
| **Kafka** | `helm-kafka/values.yaml`, `helm-kafka/values-bap.yaml`, `helm-kafka/values-bpp.yaml` | Kafka Helm chart values |
| **RabbitMQ** | `helm-rabbitmq/values.yaml`, `helm-rabbitmq/values-bap.yaml`, `helm-rabbitmq/values-bpp.yaml` | RabbitMQ Helm chart values |
| **Sandbox (REST)** | `helm-sendbox/values-sandbox.yaml` | Complete sandbox with REST API |
| **Sandbox (Kafka)** | `helm-sandbox-kafka/values-sandbox.yaml` | Complete sandbox with Kafka |
| **Sandbox (RabbitMQ)** | `helm-sandbox-rabbitMq/values-sandbox.yaml` | Complete sandbox with RabbitMQ |

---

## Important Notes

1. **Service Naming**: When using `fullnameOverride=onix` in Helm deployments, Kafka services are named `onix-kafka` and `onix-kafka-ui` (not `onix-bap-kafka` or `onix-bpp-kafka`), as they are shared resources.

2. **Path Consistency**: All message testing paths have been standardized. Use the correct paths as documented above.

3. **Technology Terminology**: 
   - **Kafka**: Uses "topics" and "Kafka CLI" commands
   - **RabbitMQ**: Uses "queues", "routing keys", "exchanges", and "RabbitMQ Management API"

4. **Cross-References**: All README cross-references have been updated to use correct relative paths (e.g., `../helm-kafka/README.md` instead of `./../../kafka/README.md`).
