# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### ONIX Adapter (onix-adaptor)

- **OTEL collector in standalone compose**: BAP and BPP Docker Compose stacks now include an OpenTelemetry collector
  - `docker-compose-onix-bap-plugin.yml`: Added `otel-collector-bap` service (OTLP gRPC receiver, health/zpages ports)
  - `docker-compose-onix-bpp-plugin.yml`: Added `otel-collector-bpp` service (host ports 4321/4322 to avoid clash with BAP)
  - Adapter sends metrics, traces, and logs via OTLP to the collector; env vars `OTEL_EXPORTER_OTLP_INSECURE` and `OTEL_EXPORTER_OTLP_ENDPOINT` set per stack
- **otel-config.yml**: New OTEL collector config in `onix-adaptor/` used by both BAP and BPP stacks (receivers, processors, pipelines for metrics/traces/logs; exports to `otel-collector-network` when present)

#### Sandbox Kafka (sandbox-kafka)

- **OTEL collectors**: Added `otel-collector-bap` and `otel-collector-bpp` services to `sandbox-kafka/docker-compose.yml` (same pattern as sandbox REST). Adapters send metrics, traces, and logs via OTLP; env vars `OTEL_EXPORTER_OTLP_INSECURE` and `OTEL_EXPORTER_OTLP_ENDPOINT` added to both adapter services; `depends_on` collector per side. Adapter image bumped to `v0.9.5`; schema path normalized to `../schemas`; optional metrics ports 9003/9004 exposed for BAP/BPP.

#### ONIX Adapter Kafka (onix-adaptor-kafka)

- **OTEL collector and config**: Added `otel-config.yml` (copy of onix-adaptor); added `otel-collector-bap` and `otel-collector-bpp` services to `docker-compose-onix-bap-kafka-plugin.yml` and `docker-compose-onix-bpp-kafka-plugin.yml` with `./otel-config.yml` mounted. Adapter image v0.9.5; OTEL env and `depends_on` collector; schema path `../schemas` when run from onix-adaptor-kafka.
- **Audit fields**: Added `config/onix-bap/audit-fields.yaml` and `config/onix-bpp/audit-fields.yaml` (PII masking for logs/traces).

### Changed

#### ONIX Adapter (onix-adaptor)

- **config.md**: Updated to match current adapter and collector configuration
  - Application: `log.contextKeys` now includes `parent_id`
  - OpenTelemetry: Documented OTLP-based setup (no metrics port), `serviceName` per side, `domain`, `otlpEndpoint`, `networkMetricsGranularity/Frequency`, `enableTracing`, `enableLogs`, `timeInterval`, `auditFieldsConfig`
  - New section: Audit Fields (PII masking) with `piiPatterns`, `piiPaths`, and example paths
  - Handlers: Documented `handler.subscriberId` for all modules; middleware uses `contextKeys` (transaction_id, message_id, parent_id) instead of `uuidKeys`
  - Schema validator: Documented extended schema options (`extendedSchema_enabled`, `extendedSchema_cacheTTL`, `extendedSchema_maxCacheSize`, etc.)
  - BPP Caller: Documented full plugin set and processing steps; config file list includes audit-fields.yaml
- **README.md**: Reworked for current setup
  - Title set to "ONIX Adapter – API Integration"; architecture describes Redis + adapter + OTEL collector per stack
  - Directory structure includes `otel-config.yml`; prerequisites clarify schema path
  - Quick Start: run from `onix-adaptor/`; verify step includes OTEL collector container
  - Volume mounts as table (adapter config, schemas, `otel-config.yml` → collector)
  - Network section lists all three services per stack and OTLP endpoint
  - Troubleshooting: OTEL collector check and verification of collector config mount
  - Customization: ports for adapter and collector; updating adapter vs `otel-config.yml`; image tag v0.9.5
  - Removed `SANDBOX_PATH`; OTEL config is local `./otel-config.yml` only
- **Docker image**: BAP and BPP compose files and README updated to use `manendrapalsingh/onix-adapter:v0.9.5` (from v0.9.3)

#### ONIX Adapter Kafka (onix-adaptor-kafka)

- **config/onix-bap/adapter.yaml** and **config/onix-bpp/adapter.yaml**: Aligned with REST adapter where applicable: `log.contextKeys` includes `parent_id`; `plugins.otelsetup` switched to OTLP (serviceName `onix-ev-charging-bap`/`onix-ev-charging-bpp`, domain `ev_charging`, otlpEndpoint, enableTracing, enableLogs, auditFieldsConfig, networkMetricsGranularity/Frequency, timeInterval); middleware `uuidKeys` replaced by `contextKeys: transaction_id, message_id, parent_id`.
- **config.md**: Configuration files list includes audit-fields.yaml; Application section documents `parent_id` in contextKeys; OpenTelemetry section replaced with OTLP table and Audit Fields (PII masking) section; Middleware documents contextKeys.
- **README.md**: Reworked to align with onix-adaptor: title "ONIX Adapter – Kafka Integration"; architecture (Kafka + Redis + adapter + OTEL collector); directory structure with otel-config.yml and audit-fields; Quick Start, Environment Variables, Volume Mounts, Network, Troubleshooting, Customization; image v0.9.5; existing Kafka plugin reference retained below.

## [v0.9.3] - 2026-01-27

### Added

#### Kafka Integration

- **Kafka Support**: Added complete Kafka integration for asynchronous message-based communication
  - `**helm-kafka/`**: Helm chart for deploying ONIX adapters with Kafka (KRaft mode, no Zookeeper)
  - `**onix-adaptor-kafka/**`: Standalone Docker Compose setup for Kafka-based ONIX adapters
  - `**sandbox-kafka/**`: Complete Docker Compose sandbox with Kafka message broker
  - `**helm-sandbox-kafka/**`: Complete Helm-based sandbox deployment with Kafka on Kubernetes
  - Kafka runs in KRaft mode (no Zookeeper required)
  - Automatic topic creation with admin client support
  - Kafka UI for topic management and monitoring
  - Message examples and test scripts for publishing to Kafka topics

#### RabbitMQ Integration

- **RabbitMQ Support**: Added complete RabbitMQ integration for queue-based asynchronous communication
  - `**helm-rabbitmq/`**: Helm chart for deploying ONIX adapters with RabbitMQ
  - `**onix-adaptor-rabbitMQ/**`: Standalone Docker Compose setup for RabbitMQ-based ONIX adapters
  - `**sandbox-rabbitMQ/**`: Complete Docker Compose sandbox with RabbitMQ message broker
  - Queue-based message consumption with manual ACK/NACK support
  - RabbitMQ Management UI for queue monitoring
  - Configurable queue arguments (TTL, max length, dead letter exchange, etc.)

#### Helm Charts

- `**helm/**`: Helm chart for REST API-based deployment on Kubernetes
  - Monolithic architecture with HTTP/REST communication
  - Separate values files for BAP and BPP (`values-bap.yaml`, `values-bpp.yaml`)
  - Kubernetes Secrets support for production deployments
  - OpenTelemetry metrics support
  - Schema validation v2 with URL-based validation
- `**helm-sendbox/**`: Alternative Helm-based sandbox deployment
  - Complete sandbox environment on Kubernetes
  - Message examples and test scripts

#### Mock Services

- `**mock/**`: Comprehensive mock service configurations and Helm charts
  - `**mock-bap/**`: Mock BAP service with Helm chart
  - `**mock-bpp/**`: Mock BPP service with Helm chart
  - `**mock-cds/**`: Mock CDS service with Helm chart
  - `**mock-registry/**`: Mock Registry service with Helm chart
  - `**mock-bap-kafka/**`: Mock BAP service with Kafka integration
  - `**mock-bpp-kafka/**`: Mock BPP service with Kafka integration
  - `**mock-bap-rabbitMq/**`: Mock BAP service with RabbitMQ integration
  - `**mock-bpp-rabbitMq/**`: Mock BPP service with RabbitMQ integration

#### Message Examples and Test Scripts

- **Kafka Message Examples**: Added comprehensive message examples for Kafka topics
  - BAP message examples: `sandbox-kafka/message/bap/example/` (16 JSON files)
  - BPP message examples: `sandbox-kafka/message/bpp/example/` (12 JSON files)
  - Test scripts for publishing messages: `sandbox-kafka/message/bap/test/` and `sandbox-kafka/message/bpp/test/`
  - Support for all EV charging actions (discover variants, select, init, confirm, track, cancel, update, rating, support)
- **RabbitMQ Message Examples**: Added message examples for RabbitMQ
  - BAP and BPP message examples in `sandbox-rabbitMQ/message/`
  - Test scripts for publishing messages via RabbitMQ

### Changed

#### Documentation

- `**README.md`**: Completely restructured to be brief and reference-only
  - Removed detailed examples and code snippets
  - Added comprehensive repository structure section
  - Organized documentation references by deployment type (Docker Compose vs Helm)
  - Added communication pattern overview (REST API, Kafka, RabbitMQ)
  - Streamlined Quick Start section with references to detailed guides

#### ONIX Adapter Configurations

- `**onix-adaptor/config/onix-bap/adapter.yaml**`: Updated for v0.9.3 compatibility
- `**onix-adaptor/config/onix-bpp/adapter.yaml**`: Updated for v0.9.3 compatibility

#### Docker Compose Files

- `**onix-adaptor/docker-compose-onix-bap-plugin.yml**`: Updated to use `manendrapalsingh/onix-adapter:v0.9.3`
- `**onix-adaptor/docker-compose-onix-bpp-plugin.yml**`: Updated to use `manendrapalsingh/onix-adapter:v0.9.3`

### Features

- **Multiple Communication Patterns**: Support for REST API, Kafka, and RabbitMQ
- **Kubernetes Deployment**: Complete Helm chart support for all communication patterns
- **Production Ready**: Secret management, health checks, OpenTelemetry metrics, structured logging
- **Schema Validation v2**: URL-based schema validation from Beckn protocol specifications
- **KRaft Mode**: Kafka runs without Zookeeper for simplified deployment
- **Queue Management**: Advanced RabbitMQ queue configuration with TTL, dead letter queues, and priority support

## [v0.9.2] - 2026-01-13

### Changed

#### Docker Compose Files

- `**onix-adaptor/docker-compose-onix-bap-plugin.yml`**:
  - Updated Docker image version from `v0.9.1` to `v0.9.2`
    - `onix-bap-plugin`: Updated to `manendrapalsingh/onix-adapter:v0.9.2`
- `**onix-adaptor/docker-compose-onix-bpp-plugin.yml**`:
  - Updated Docker image version from `v0.9.1` to `v0.9.2`
    - `onix-bpp-plugin`: Updated to `manendrapalsingh/onix-adapter:v0.9.2`

#### ONIX Adapter Configurations

- `**onix-adaptor/config/onix-bap/adapter.yaml**`:
  - Updated schema validator configuration:
    - Changed schema location from `protocol-specifications-new/refs/heads/main` to `protocol-specifications-v2/refs/heads/core-v2.0.0-rc`
    - Updated URL: `https://raw.githubusercontent.com/beckn/protocol-specifications-v2/refs/heads/core-v2.0.0-rc/api/beckn.yaml`
    - Applied to both `bapTxnReceiver` and `bapTxnCaller` modules
- `**onix-adaptor/config/onix-bpp/adapter.yaml**`:
  - Updated schema validator configuration:
    - Changed schema location from `protocol-specifications-new/refs/heads/main` to `protocol-specifications-v2/refs/heads/core-v2.0.0-rc`
    - Updated URL: `https://raw.githubusercontent.com/beckn/protocol-specifications-v2/refs/heads/core-v2.0.0-rc/api/beckn.yaml`
    - Applied to both `bppTxnReceiver` and `bppTxnCaller` modules

#### Configuration Documentation

- `**config.md**`:
  - Updated cache configuration documentation for both BAP and BPP adapters:
    - Updated Redis address from local Docker service names to `redis.example.com:6380`
    - Added `use_tls: "true"` configuration option for secure Redis connections
    - Documented TLS support for cache plugin configuration

### Added

- **Redis TLS Support**: Added TLS configuration option for Redis cache connections
  - Enables secure connections to Redis instances using TLS/SSL
  - Configurable via `plugins.cache.config.use_tls` setting
  - Supports external Redis services with TLS enabled

## [v0.9.1] - 2026-01-12

### Changed

#### Docker Compose Files

- `**sandbox/docker-compose.yml`**:
  - Updated ONIX adapter Docker images from `v0.9.0` to `v0.9.1`:
    - `onix-bap-plugin`: Updated to `manendrapalsingh/onix-adapter:v0.9.1`
    - `onix-bpp-plugin`: Updated to `manendrapalsingh/onix-adapter:v0.9.1`
- `**onix-adaptor/docker-compose-onix-bap-plugin.yml**`:
  - Updated Docker image version from `latest` to `v0.9.1`
- `**onix-adaptor/docker-compose-onix-bpp-plugin.yml**`:
  - Updated Docker image version from `latest` to `v0.9.1`

### Fixed

- **Schema Validator**: Re-enabled schema validation in ONIX adapter v0.9.1
  - Schema validation now uses remote URL-based validation from Beckn protocol specifications
  - Validation performed against `https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/api/beckn.yaml`

---

## [v0.9.0] - 2025-12-31

### Removed

- **Schemas Directory**: Removed entire `schemas/` directory and all JSON schema validation files
  - Removed `schemas/README.md` (257 lines)
  - Removed all JSON schema files for Beckn protocol v2.0.0 (24 files, ~6,113 lines):
    - **Action schemas**: `discover.json`, `select.json`, `init.json`, `confirm.json`, `update.json`, `track.json`, `cancel.json`, `rating.json`, `support.json`
    - **Callback schemas**: `on_discover.json`, `on_select.json`, `on_init.json`, `on_confirm.json`, `on_update.json`, `on_track.json`, `on_cancel.json`, `on_rating.json`, `on_support.json`, `on_status.json`
    - **Aggregate schema**: `all.json`
  - **Total impact**: ~6,370 lines of schema definitions removed
  - Schema validation has been disabled in adapter configurations (see Changed section)

### Changed

#### Configuration Files

##### ONIX Adapter Configurations

- `**onix-adaptor/config/onix-bap/adapter.yaml`**:
  - Added OpenTelemetry plugin configuration (`otelsetup`) with metrics support
    - Service name: `beckn-onix`
    - Service version: `1.0.0`
    - Metrics enabled: `true`
    - Environment: `development`
    - Metrics port: `9003`
  - Commented out `schemaValidator` plugin configuration (schema validation disabled)
  - Updated routing configuration paths:
    - Changed from `/app/config/onix-bap/bap_receiver_routing.yaml` to `/app/config/bap_receiver_routing.yaml`
    - Changed from `/app/config/onix-bap/bap_caller_routing.yaml` to `/app/config/bap_caller_routing.yaml`
  - Commented out `validateSchema` step in both `bapTxnReceiver` and `bapTxnCaller` processing pipelines
- `**onix-adaptor/config/onix-bpp/adapter.yaml**`:
  - Added OpenTelemetry plugin configuration (`otelsetup`) with metrics support
    - Service name: `beckn-onix`
    - Service version: `1.0.0`
    - Metrics enabled: `true`
    - Environment: `development`
    - Metrics port: `9004`
  - Commented out `schemaValidator` plugin configuration (schema validation disabled)
  - Updated routing configuration paths:
    - Changed from `/app/config/onix-bpp/bpp_receiver_routing.yaml` to `/app/config/bpp_receiver_routing.yaml`
    - Changed from `/app/config/onix-bpp/bpp_caller_routing.yaml` to `/app/config/bpp_caller_routing.yaml`
  - Commented out `validateSchema` step in both `bppTxnReceiver` and `bppTxnCaller` processing pipelines

##### Docker Compose Files

- `**onix-adaptor/docker-compose-onix-bap-plugin.yml**`:
  - Updated Docker image version from `latest` to `v0.9.0`
  - Added metrics port mapping: `9003:9003` for OpenTelemetry metrics
  - Simplified volume mount configuration:
    - Changed from mounting specific config files to mounting entire config directory
    - Updated mount path from `/app/config/onix-bap` to `/app/config`
  - Added `REDIS_PASSWORD` environment variable for Redis authentication
- `**onix-adaptor/docker-compose-onix-bpp-plugin.yml**`:
  - Updated Docker image version from `latest` to `v0.9.0`
  - Added metrics port mapping: `9004:9004` for OpenTelemetry metrics
  - Simplified volume mount configuration:
    - Changed from mounting specific config files to mounting entire config directory
    - Updated mount path from `/app/config/onix-bpp` to `/app/config`
  - Added `REDIS_PASSWORD` environment variable for Redis authentication
- `**sandbox/docker-compose.yml**`:
  - Updated ONIX adapter Docker images from `latest` to `v0.9.0`:
    - `onix-bap-plugin`: Updated to `manendrapalsingh/onix-adapter:v0.9.1`
    - `onix-bpp-plugin`: Updated to `manendrapalsingh/onix-adapter:v0.9.1`
  - Added metrics port mappings:
    - BAP adapter: `9003:9003`
    - BPP adapter: `9004:9004`
  - Simplified volume mount configuration:
    - Changed from mounting specific config files to mounting entire config directory
    - Updated to use `${CONFIG_PATH}` environment variable for flexible config path
    - Changed mount paths from `/app/config/onix-bap` and `/app/config/onix-bpp` to `/app/config`
  - Added `REDIS_PASSWORD` environment variable to both adapter services

#### API Documentation

##### Swagger/OpenAPI Specifications

- `**api-collection/swagger/bpp.yaml**`:
  - Reordered endpoint definitions for better organization:
    - Moved `on_cancel` endpoint before `on_status`
    - Moved `on_rating` endpoint before `on_support`
    - Moved `on_support` endpoint before `on_status`
  - Updated endpoint descriptions and operation IDs to match reordered structure
  - Updated example file references to align with new endpoint order
  - Removed 28 lines of deprecated or redundant content
  - **Total changes**: 98 lines modified
- `**api-collection/swagger/bap.yaml`**:
  - Minor updates to align with BPP specification changes
  - **Total changes**: 28 lines removed

##### Postman Collections

- `**api-collection/postman-collection/bap/BAP-DEG-EV-Charging-All-APIs.postman_collection.json`**:
  - Minor updates to align with API specification changes
  - **Total changes**: 4 lines modified
- `**api-collection/postman-collection/bpp/BPP-DEG-EV-Charging-All-APIs.postman_collection.json`**:
  - Minor updates to align with API specification changes
  - **Total changes**: 4 lines modified

##### Documentation Files

- `**api-collection/README.md`**:
  - Enhanced API alignment documentation
  - Updated content to reflect current API structure
  - **Total changes**: 15 lines modified
- `**api-collection/field-description/FIELD_REFERENCE.md`**:
  - Minor updates to field descriptions
  - **Total changes**: 3 lines modified
- `**README.md`**:
  - Minor documentation update
  - **Total changes**: 1 line added

#### Example Files

- `**sandbox/request.json`**:
  - Significant restructuring of request examples
  - Updated request examples to align with current API specifications
  - Improved example structure and formatting
  - **Total changes**: 636 lines modified (net reduction in file size)

### Added

- **OpenTelemetry Integration**: Added OpenTelemetry plugin support to both BAP and BPP adapters
  - Metrics collection enabled
  - Separate metrics ports for BAP (9003) and BPP (9004)
  - Service name and version tracking
  - Environment configuration support
- **Redis Authentication**: Added `REDIS_PASSWORD` environment variable support
  - Configured in all Docker Compose files
  - Enables secure Redis connections
- **Flexible Configuration Paths**: Added `${CONFIG_PATH}` environment variable support
  - Allows dynamic configuration path specification
  - Simplifies deployment across different environments

## [v0.8.0] - 2025-12-22

### Summary

- Initial release with complete sandbox environment
- ONIX adapter integration for BAP and BPP
- Mock services for testing (BAP, BPP, CDS, Registry)
- Complete API documentation (Swagger/OpenAPI and Postman collections)
- JSON schema validation support
- Docker Compose setup for easy deployment

---

**Statistics for v0.9.0:**

- **Files changed**: 34 files
- **Files removed**: 25 files (all schema files)
- **Files modified**: 13 files
- **Lines added**: ~397 lines
- **Lines removed**: ~6,370 lines
- **Net change**: -5,973 lines

