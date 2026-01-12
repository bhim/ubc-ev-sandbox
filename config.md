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
| `plugins.cache.config.addr` | `redis-onix-bap:6379` | Redis address for caching |
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
| `plugins.cache.config.addr` | `redis-onix-bpp:6379` | Redis address for caching |
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
