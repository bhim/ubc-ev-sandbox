# Kafka Integration

This guide demonstrates how to integrate the **onix-adapter** with BAP and BPP applications using **Docker containers** with **Apache Kafka** event streaming. The same configuration works for both monolithic and microservice architectures.

## Architecture Overview

In this setup, the onix-adapter uses Apache Kafka for high-throughput event streaming. Services communicate through Kafka topics, enabling scalable, distributed message processing.

### Components

- **Redis**: Used for caching and state management
- **Apache Kafka**: Event streaming platform for high-throughput messaging
- **Zookeeper**: (if required) For Kafka coordination and metadata management
- **Onix-Adapter**: Container handling all BAP/BPP operations via Kafka

## Directory Structure

```
onix-adaptor-kafka/
├── config/
│   ├── onix-bap/
│   │   ├── adapter.yaml
│   │   ├── bapTxnCaller-routing.yaml
│   │   └── bapTxnReciever-routing.yaml
│   └── onix-bpp/
│       ├── adapter.yaml
│       ├── bppTxnCaller-routing.yaml
│       └── bppTxnReciever-routing.yaml
├── docker-compose-onix-bap-kafka-plugin.yml    # BAP service configuration
├── docker-compose-onix-bpp-kafka-plugin.yml    # BPP service configuration
└── README.md
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Access to onix-adapter Docker image:
  - `manendrapalsingh/onix-adapter:v0.9.2`
- Kafka server (included in docker-compose)
- Redis server (included in docker-compose)

## Architecture

### BAP Adapter Modules

1. **bapTxnCaller**: Kafka consumer that consumes requests from BAP Backend and routes them to BPP via HTTP
2. **bapTxnReceiver**: HTTP handler that receives callbacks from BPP and publishes them to BAP Backend via Kafka

### BPP Adapter Modules

1. **bppTxnCaller**: Kafka consumer that consumes callbacks from BPP Backend and routes them to BAP/CDS via HTTP
2. **bppTxnReceiver**: HTTP handler that receives requests from BAP adapter and publishes them to BPP Backend via Kafka

## Features

- **Event Streaming**: High-throughput, distributed event processing
- **Scalability**: Kafka's distributed architecture supports horizontal scaling
- **Durability**: Messages are persisted and replicated across Kafka brokers
- **Consumer Groups**: Support for parallel message processing
- **Topic-Based Routing**: Messages routed by topic names
- **Manual Offset Management**: Control over message consumption
- **Phase 1 Support**: Routes discover requests to CDS for aggregation
- **Phase 2+ Support**: Routes requests directly to BPP and receives callbacks

## Quick Start

### For BAP (Buyer App Provider)

1. **Start the BAP services:**
   ```bash
   docker-compose -f docker-compose-onix-bap-kafka-plugin.yml up -d
   ```

2. **Verify services are running:**
   ```bash
   docker ps | grep -E "(redis-onix-bap|onix-bap-plugin-kafka|kafka|zookeeper)"
   ```

3. **Check logs:**
   ```bash
   docker-compose -f docker-compose-onix-bap-kafka-plugin.yml logs -f onix-bap-plugin-kafka
   ```

### For BPP (Buyer Platform Provider)

1. **Start the BPP services:**
   ```bash
   docker-compose -f docker-compose-onix-bpp-kafka-plugin.yml up -d
   ```

2. **Verify services are running:**
   ```bash
   docker ps | grep -E "(redis-onix-bpp|onix-bpp-plugin-kafka|kafka|zookeeper)"
   ```

3. **Check logs:**
   ```bash
   docker-compose -f docker-compose-onix-bpp-kafka-plugin.yml logs -f onix-bpp-plugin-kafka
   ```

## Configuration

### Required Services

1. **Kafka**: Event streaming platform (default: `kafka:9092`)
2. **Zookeeper**: (if required) For Kafka coordination (default: `zookeeper:2181`)
3. **Redis**: Cache server 
   - BAP: `redis-onix-bap:6379`
   - BPP: `redis-onix-bpp:6379`
4. **Registry**: Mock registry service (default: `http://mock-registry:3030`)

### Environment Variables

- `CONFIG_FILE`: Path to the adapter configuration file
  - BAP: `/app/config/adapter.yaml`
  - BPP: `/app/config/adapter.yaml`
- `REDIS_PASSWORD`: Redis password for authentication (default: `your-redis-password`)

### Kafka Configuration

#### Topic Configuration

- **Topic Naming**: Topics follow the pattern `{domain}.{action}` (e.g., `bap.discover`, `bpp.on_discover`)
- **Topic Durability**: Topics are persistent and replicated
- **Partitioning**: Topics can be partitioned for parallel processing
- **Consumer Groups**: Each adapter uses a consumer group for message distribution
- **Automatic Topic Creation**: The adapter can automatically create missing topics on startup using the admin client

#### BAP bapTxnCaller (Kafka Consumer)

The adapter consumes requests from BAP Backend with the following configuration:

- **Topics** (requests from BAP Backend): 
  - `bap.discover` - Discover request
  - `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support` - Other requests
- **Consumer Group**: `bap_caller_group`
- **Offset Management**: Manual or automatic based on configuration
- **Processing**: Messages are processed through configured steps (`validateSchema`, `addRoute`, `sign`)
- **Admin Topic Management**: Automatically creates missing topics on startup when enabled

#### BAP bapTxnReceiver (HTTP Handler + Publisher)

The adapter publishes callbacks to BAP Backend with the following configuration:

- **HTTP Endpoint**: `/bap/receiver/` (receives HTTP requests from BPP adapter)
- **Publishing Topics** (callbacks to BAP Backend):
  - `bap.on_discover` - Phase 1 aggregated search results
  - `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support`, `bap.on_default` - Phase 2+ callbacks
- **Admin Topic Management**: Automatically creates missing topics on startup when enabled

#### BPP bppTxnCaller (Kafka Consumer)

The adapter consumes callbacks from BPP Backend with the following configuration:

- **Topics** (callbacks from BPP Backend): 
  - `bpp.on_discover` - Phase 1 on_discover callback
  - `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support` - Phase 2+ callbacks
  - `bpp.catalog_publish` - Catalog publish request
  - `bpp.on_catalog_publish` - Catalog publish callback
- **Consumer Group**: `bpp_caller_group`
- **Offset Management**: Manual or automatic based on configuration
- **Admin Topic Management**: Automatically creates missing topics on startup when enabled

#### BPP bppTxnReceiver (HTTP Handler + Publisher)

The adapter publishes requests to BPP Backend with the following configuration:

- **HTTP Endpoint**: `/bpp/receiver/` (receives HTTP requests from BAP adapter)
- **Publishing Topics** (requests to BPP Backend):
  - `bpp.discover` - Phase 1 discover request
  - `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support`, `bpp.default` - Phase 2+ requests
  - `bpp.catalog_publish` - Catalog publish request
  - `bpp.on_catalog_publish` - Catalog publish callback
- **Admin Topic Management**: Automatically creates missing topics on startup when enabled

### Sandbox Reference Environment

A fully-wired sandbox that mirrors this setup is available under `sandbox/docker/kafka/`.  
It adds the supporting mock services (registry, CDS, mock BAP/BPP backends) together with ready-to-use Kafka
message publishers. Key locations:

- `sandbox/docker/kafka/docker-compose.yml` — spins up Kafka, Zookeeper, both ONIX plugins and mocks
- `sandbox/docker/kafka/mock-*.yml` — configuration for the mock registry, CDS, BAP and BPP Kafka services
- `sandbox/docker/kafka/message/bap|bpp/` — sample payloads plus helper scripts (`publish-all.sh`,
  `publish-<action>.sh`) that publish test traffic to Kafka via `kafka-console-producer.sh`

> Tip: run `./publish-all.sh` from either message directory to send a full suite of sample events after the
> sandbox compose stack is up (`docker compose up -d` from the same folder).

### HTTP Configuration

**HTTP server is required** for the Receiver modules to receive HTTP requests. The HTTP configuration must be enabled in `adapter.yaml`:

**BAP Adapter:**
```yaml
http:
  port: 8001
  timeout:
    read: 30
    write: 30
    idle: 30
```

**BPP Adapter:**
```yaml
http:
  port: 8002
  timeout:
    read: 30
    write: 30
    idle: 30
```

- **BAP Port**: 8001 (must be exposed in Docker Compose)
- **BPP Port**: 8002 (must be exposed in Docker Compose)
- **Purpose**: Enables Receiver modules to receive HTTP requests/callbacks

## Message Flow

### Flow 1: BAP Backend → BPP Backend (Requests)

1. **BAP Backend**: Publishes requests to Kafka topics like `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, etc.
2. **bapTxnCaller**: Consumes from Kafka topics, processes, routes to BPP adapter via HTTP
3. **bppTxnReceiver**: Receives HTTP request at `/bpp/receiver/`, processes, publishes to Kafka
4. **BPP Backend**: Consumes from Kafka topics like `bpp.discover`, `bpp.select`, `bpp.init`, `bpp.confirm`, etc.

### Flow 2: BPP Backend → BAP Backend (Callbacks)

1. **BPP Backend**: Publishes callbacks to Kafka topics like `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, etc.
2. **bppTxnCaller**: Consumes from Kafka topics, processes, routes to BAP adapter via HTTP
3. **bapTxnReceiver**: Receives HTTP request at `/bap/receiver/`, processes, publishes to Kafka
4. **BAP Backend**: Consumes callbacks from Kafka topics like `bap.on_discover`, `bap.on_select`, `bap.on_init`, `bap.on_confirm`, etc.

### Flow 3: BPP Backend → Discovery Indexer (Catalog Publish)

1. **BPP Backend**: Publishes `catalog_publish` request to Kafka topic `bpp.catalog_publish`
2. **bppTxnCaller**: Consumes from Kafka topic, processes, routes to discovery indexer via HTTP
3. **Discovery Indexer**: Processes catalog and sends `on_catalog_publish` callback via HTTP
4. **bppTxnReceiver**: Receives HTTP callback at `/bpp/receiver/`, processes, publishes to Kafka
5. **BPP Backend**: Consumes catalog processing results from Kafka topic `bpp.on_catalog_publish`

## Kafka Management

### Using Kafka CLI Tools

```bash
# List topics
docker exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092

# Create a topic
docker exec kafka kafka-topics.sh --create --topic bap.discover --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# Describe a topic
docker exec kafka kafka-topics.sh --describe --topic bap.discover --bootstrap-server localhost:9092

# Consume messages from a topic
docker exec kafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic bap.discover --from-beginning

# Produce messages to a topic
docker exec -it kafka kafka-console-producer.sh --bootstrap-server localhost:9092 --topic bap.discover
```

### Consumer Group Management

```bash
# List consumer groups
docker exec kafka kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# Describe consumer group
docker exec kafka kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group bap_caller_group

# Reset consumer group offsets
docker exec kafka kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group bap_caller_group --reset-offsets --to-earliest --topic bap.discover --execute
```

## Stopping Services

```bash
# Stop BAP services
docker-compose -f docker-compose-onix-bap-kafka-plugin.yml down

# Stop BPP services
docker-compose -f docker-compose-onix-bpp-kafka-plugin.yml down

# Stop both and remove volumes
docker-compose -f docker-compose-onix-bap-kafka-plugin.yml -f docker-compose-onix-bpp-kafka-plugin.yml down -v
```

## Troubleshooting

### Kafka Connection Issues

- Verify Kafka is running: `docker ps | grep kafka`
- Check Kafka logs: `docker logs kafka`
- Verify network connectivity: Ensure plugin container can reach `kafka:9092`
- Check broker configuration: Verify `bootstrap.servers` in adapter config

### Messages Not Consumed

- Verify topics exist: Use `kafka-topics.sh --list` to list topics
- Check consumer group status: Use `kafka-consumer-groups.sh --describe`
- Review adapter logs: `docker logs onix-bap-plugin-kafka` or `docker logs onix-bpp-plugin-kafka`
- Verify topic names match: Check topic names in adapter config match your Backend producer

### Offset Issues

- Check consumer group offsets: Use `kafka-consumer-groups.sh --describe`
- Reset offsets if needed: Use `kafka-consumer-groups.sh --reset-offsets`
- Verify offset management mode: Check if using manual or automatic offset commits

### HTTP Endpoint Issues

- Verify HTTP port is exposed in Docker Compose (8001 for BAP, 8002 for BPP)
- Check HTTP configuration is enabled in `adapter.yaml`
- Verify network connectivity between adapters
- Check adapter logs for HTTP connection errors

### Consumer Issues

1. **No Consumers Connected**:
   - Check adapter logs: `docker logs onix-bap-plugin-kafka` or `docker logs onix-bpp-plugin-kafka`
   - Verify Kafka connection in logs
   - Check network connectivity
   - Verify broker addresses in `adapter.yaml`

2. **Messages Not Being Consumed**:
   - Verify consumer group is active (use Kafka CLI tools)
   - Check if messages are in topics (use `kafka-console-consumer.sh`)
   - Verify topic names match between producer and consumer
   - Check adapter logs for errors

## Customization

### Kafka Configuration Examples

#### Producer Configuration with Admin Topic Management

```yaml
publisher:
  id: publisher
  config:
    type: kafka
    brokers: kafka:9092
    topic: bap.on_default
    compressionCodec: snappy
    acks: all
    admin.enabled: "on"
    admin.topicSpecs: '[{"topic":"bap.on_discover","numPartitions":1,"replicationFactor":1},{"topic":"bap.on_select","numPartitions":1,"replicationFactor":1},{"topic":"bap.on_init","numPartitions":1,"replicationFactor":1}]'
```

#### Consumer Configuration with Admin Topic Management

```yaml
consumer:
  id: consumer
  config:
    subscriberId: ev-charging.sandbox1.com
    role: bap
    consumerType: kafka
    consumerThreads: "2"
    consumer.id: kafkaconsumer
    consumer.brokers: kafka:9092
    consumer.topics: "bap.discover,bap.select,bap.init"
    consumer.groupId: bap_caller_group
    consumer.autoCommit: "false"
    consumer.maxRetry: "3"
    consumer.useTLS: "false"
    consumer.tlsInsecureSkipVerify: "false"
    consumer.tlsCAFile: ""
    consumer.tlsCertFile: ""
    consumer.tlsKeyFile: ""
    consumer.dialTimeout: "10s"
    consumer.sessionTimeout: "30s"
    consumer.heartbeatInterval: "3s"
    consumer.maxPollInterval: "5m"
    consumer.maxPollRecords: "500"
    consumer.rebalanceTimeout: "30s"
    consumer.startOffset: "latest"
    consumer.readBackoffMin: "100ms"
    consumer.readBackoffMax: "1s"
    consumer.admin.enabled: "on"
    consumer.admin.topicSpecs: '[{"topic":"bap.discover","numPartitions":1,"replicationFactor":1},{"topic":"bap.select","numPartitions":1,"replicationFactor":1},{"topic":"bap.init","numPartitions":1,"replicationFactor":1}]'
    steps: '["addRoute", "validateSchema", "sign"]'
```

### Admin Topic Management

The Kafka integration includes automatic topic creation functionality. When enabled, the plugin will automatically create missing Kafka topics before initializing the consumer or producer.

**Configuration**:
- `admin.enabled`: Set to `"on"` or `"true"` to enable automatic topic creation
- `admin.topicSpecs`: JSON array of topic specifications

**Topic Specification Format**:
```json
[
  {
    "topic": "topic-name",
    "numPartitions": 1,
    "replicationFactor": 1
  }
]
```

**Features**:
- Automatically checks for existing topics before creating
- Only creates missing topics (idempotent)
- Supports TLS configuration for admin client
- Configurable partitions and replication factor per topic
- Defaults: 1 partition and replication factor 1 if not specified

### Updating Configuration

1. Modify the YAML files in `config/onix-{bap|bpp}/`
2. Restart the services:
   ```bash
   docker-compose -f docker-compose-onix-{bap|bpp}-kafka-plugin.yml restart
   ```

## Next Steps

- For RabbitMQ integration: See [RabbitMQ Integration](./../rabbitmq/README.md)
- For API integration: See [Monolithic API](./../api/monolithic/README.md) or [Microservice API](./../api/microservice/README.md)

## Additional Resources

- [ONIX Protocol Documentation](https://github.com/beckn/onix)
- [BAP/BPP Specification](https://github.com/beckn/protocol-specifications)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
