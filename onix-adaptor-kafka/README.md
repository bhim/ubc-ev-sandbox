# Kafka Integration for Beckn-ONIX

This directory contains the Kafka producer and consumer implementations for the Beckn-ONIX adapter.

## Configuration

All configuration is provided through adapter YAML files. Environment variables are not used.

### YAML Configuration Example

```yaml
modules:
  - name: bapHandler
    path: /bap
    handler:
      type: std
      role: bap
      subscriberId: "bap-onix"
      plugins:
        kafkaProducer:
          id: kafka_producer
          config:
            brokers: "kafka:9092"
            topic: "bpp.requests"
            compressionCodec: "snappy"
            acks: "all"
            admin.enabled: "on"
            admin.topicSpecs: '[{"topic":"bpp.requests","numPartitions":3,"replicationFactor":1}]'
        
        kafkaConsumer:
          id: kafka_consumer
          config:
            brokers: "kafka:9092"
            topics: "bap.responses,bap.errors"
            groupId: "bap-onix-consumer"
            autoCommit: "true"
            admin.enabled: "on"
            admin.topicSpecs: '[{"topic":"bap.responses","numPartitions":3,"replicationFactor":1},{"topic":"bap.errors","numPartitions":3,"replicationFactor":1}]'
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
    "numPartitions": 3,
    "replicationFactor": 1
  }
]
```

**Example**:
```yaml
consumer:
  id: consumer
  config:
    consumerType: kafka
    consumer.brokers: kafka:9092
    consumer.topics: "bap.discover,bap.select"
    consumer.groupId: bap_group
    consumer.admin.enabled: "on"
    consumer.admin.topicSpecs: '[{"topic":"bap.discover","numPartitions":3,"replicationFactor":1},{"topic":"bap.select","numPartitions":3,"replicationFactor":1}]'
```

**Features**:
- Automatically checks for existing topics before creating
- Only creates missing topics (idempotent)
- Supports TLS configuration for admin client
- Configurable partitions and replication factor per topic
- Defaults: 3 partitions and replication factor 1 if not specified

**TLS Support**:
When using TLS, the admin client will use the same TLS configuration as the consumer/producer:
- `useTLS`: Enable TLS (`"true"` or `"false"`)
- `tlsCAFile`: Path to CA certificate file
- `tlsCertFile`: Path to client certificate file
- `tlsKeyFile`: Path to client key file
- `tlsInsecureSkipVerify`: Skip TLS verification (`"true"` or `"false"`)
- `dialTimeout`: Connection timeout (e.g., `"10s"`)

## Building Plugins

Build the Kafka producer plugin:

```bash
cd pkg/plugin/implementation/kafka/producer/cmd
go build -buildmode=plugin -o kafka_producer.so
```

Build the Kafka consumer plugin:

```bash
cd pkg/plugin/implementation/kafka/consumer/cmd
go build -buildmode=plugin -o kafka_consumer.so
```

Build both:

```bash
#!/bin/bash
# build-kafka-plugins.sh

set -e

PLUGINS_DIR="./plugins"
mkdir -p "$PLUGINS_DIR"

# Build Kafka Producer
cd pkg/plugin/implementation/kafka/producer/cmd
go build -buildmode=plugin -o "$PLUGINS_DIR/kafka_producer.so"
echo "✓ Built kafka_producer.so"
cd -

# Build Kafka Consumer
cd pkg/plugin/implementation/kafka/consumer/cmd
go build -buildmode=plugin -o "$PLUGINS_DIR/kafka_consumer.so"
echo "✓ Built kafka_consumer.so"
cd -

echo "✓ All Kafka plugins built successfully"
```

## Usage

### As a Message Publisher

The Kafka producer can be used as a routing destination instead of RabbitMQ:

```yaml
routing:
  - pattern: ".*"
    targetType: "kafka"
    kafkaTopics:
      - "bpp.search.requests"
```

### As a Message Consumer

The topic consumer handler processes messages from Kafka:

```yaml
modules:
  - name: topicConsumer
    path: /consumer
    handler:
      type: std
      plugins:
        kafkaConsumer:
          id: kafka_consumer
          config:
            brokers: "kafka:9092"
            topics: "bap.requests"
            groupId: "bap-consumer"
            autoCommit: "false"
```

## Features

### Producer Features

- **Multiple Brokers**: Connect to multiple Kafka broker instances
- **Compression**: Support for Snappy, GZip, LZ4, and Zstd compression
- **Acknowledgments**: Configurable acknowledgment levels (None, One, All)
- **Batch Writing**: Optimized message batching
- **Automatic Retry**: Kafka client-level retry with configurable backoff (up to 2 minutes by default)
- **Idempotent Delivery**: Prevents duplicate messages during retries
- **Broker Disconnection Resilience**: Automatically retries failed requests when broker reconnects
- **Automatic Topic Creation**: Optional admin client for creating topics on startup

### Consumer Features

- **Consumer Groups**: Built-in consumer group support for parallel processing
- **Auto-Commit**: Optional automatic offset committing
- **Multi-Topic Subscription**: Subscribe to multiple topics simultaneously
- **Broker Disconnection Resilience**: Service stays running during broker outages, auto-reconnects
- **Transient Error Handling**: Automatically retries on broker/coordinator/network errors
- **Concurrent Processing**: Multi-threaded message processing
- **Automatic Topic Creation**: Optional admin client for creating topics on startup

### Admin Features

- **Topic Management**: Shared admin client for topic creation
- **Idempotent Operations**: Only creates missing topics
- **Configurable Partitions**: Set number of partitions per topic
- **Replication Control**: Configure replication factor per topic
- **TLS Support**: Full TLS support for secure topic management

## Dependencies

- `github.com/confluentinc/confluent-kafka-go/v2`: Go bindings for librdkafka

## Testing

Run unit tests:

```bash
# Test producer
go test ./pkg/plugin/implementation/kafka/producer/...

# Test consumer
go test ./pkg/plugin/implementation/kafka/consumer/...
```

Run integration tests (requires running Kafka):

```bash
# Start Kafka locally (KRaft mode, no Zookeeper needed)
docker-compose up -d kafka

# Run tests with Kafka
go test -tags=integration ./pkg/plugin/implementation/kafka/...
```

## Performance Tuning

### Producer Tuning

- **BatchBytes**: Increase for higher throughput, decrease for lower latency
- **WriteMaxAttempts**: Increase for higher reliability
- **Balancer**: LeastBytes balancer distributes writes evenly

### Consumer Tuning

- **ConsumerThreads**: Increase for higher parallelism
- **MaxPartitionFetchBytes**: Increase to allow larger batches per partition
- **FetchMinBytes**: Increase to wait for more data per fetch

### Supported Kafka Consumer Properties

The following Kafka properties are supported by librdkafka (Confluent Kafka Go client) and can be configured through adapter configuration (`consumer.*`):

| Kafka Property (`librdkafka`) | Adapter Config Key (`consumer.*`) | Description |
|-------------------------------|------------------------------------|-------------|
| `bootstrap.servers`           | `consumer.brokers`                 | Comma-separated broker addresses |
| `group.id`                    | `consumer.groupId`                 | Consumer group ID |
| `enable.auto.commit`          | `consumer.autoCommit`              | Auto-commit offsets (`"true"` or `"false"`) |
| `auto.offset.reset`           | `consumer.startOffset`             | Start offset (`"latest"` or `"earliest"`) |
| `fetch.min.bytes`             | `consumer.fetchMinBytes`           | Minimum bytes to fetch (integer) |
| `max.partition.fetch.bytes`   | `consumer.maxPartitionFetchBytes`  | Max bytes per partition (integer). If not set, estimated from `maxPollRecords` |
| `session.timeout.ms`          | `consumer.sessionTimeout`          | Session timeout (duration, e.g., `"30s"`) |
| `heartbeat.interval.ms`       | `consumer.heartbeatInterval`       | Heartbeat interval (duration, e.g., `"3s"`) |
| `max.poll.interval.ms`        | `consumer.maxPollInterval`         | Max poll interval (duration, e.g., `"5m"`) |
| `fetch.wait.max.ms`           | `consumer.fetchMaxWaitTime`        | Max wait time for fetch (duration, e.g., `"500ms"`) |
| `socket.timeout.ms`           | `consumer.dialTimeout`             | Socket timeout (duration, e.g., `"10s"`) |
| `auto.commit.interval.ms`     | `consumer.commitInterval`          | Auto-commit interval (duration, e.g., `"10s"`, only when auto-commit enabled) |

> **Note**: 
> - `consumer.maxPollRecords` is used for internal channel buffering and to estimate `max.partition.fetch.bytes` when not explicitly provided
> - All configuration must be provided through adapter YAML files (`adapter.yaml`), not environment variables
> - Properties not listed above are not supported by librdkafka

### Broker Disconnection Resilience

#### Consumer Resilience

The consumer automatically handles transient broker/coordinator/network errors without shutting down the service. It uses **exponential backoff with jitter** to prevent CPU storms during extended outages.

**Transient Errors (Auto-Retry with Exponential Backoff)**:
- `ErrAllBrokersDown` - All brokers are down
- `ErrBrokerNotAvailable` - Broker temporarily unavailable
- `ErrNetworkException` - Network connectivity issues
- `ErrLeaderNotAvailable` - Partition leader not available
- `ErrRequestTimedOut` - Request timeout
- "broker", "coordinator", "disconnected" - Connection issues
- "connection refused/reset" - Network problems
- **DNS Resolution Failures (Critical for Docker/Kubernetes)**:
  - "failed to resolve"
  - "no such host"
  - "name or service not known"
  - "temporary failure in name resolution"
  - "host resolution"

**Exponential Backoff Behavior**: 
- **Initial backoff**: 1 second
- **Backoff progression**: Doubles on each retry (1s → 2s → 4s → 8s → 16s → 30s)
- **Maximum backoff**: 30 seconds
- **Jitter**: Random jitter (0-50% of backoff) added to prevent thundering herd
- **Reset**: Backoff resets to 1s after successful message consumption
- Consumer logs warnings: `"Transient Kafka error (will auto-retry in Xs): ..."`
- Service stays running during broker outages
- **Never exits** on transient errors - retries indefinitely
- Automatically reconnects when broker comes back online

**Benefits**:
- ✅ Survives broker restarts without manual intervention
- ✅ Handles DNS failures during container orchestration (Docker/Kubernetes)
- ✅ Prevents CPU storms during extended outages
- ✅ Fast recovery (1s) when broker returns quickly
- ✅ Efficient retry (30s max) for prolonged outages

**Example Log Output**:
```
WARN Transient Kafka error (will auto-retry in 1s): 2/2 brokers are down
WARN Transient Kafka error (will auto-retry in 2s): kafka:9092/1: Disconnected
WARN Transient Kafka error (will auto-retry in 4s): Failed to resolve 'kafka:9092': Name or service not known
WARN Transient Kafka error (will auto-retry in 8s): GroupCoordinator: kafka:9092: Connect to ipv4#172.23.0.4:9092 failed: Connection refused
```

**Testing Broker Recovery**:
```bash
# Test automatic recovery (20s downtime)
docker stop kafka ; sleep 20s ; docker start kafka
# Expected: Consumer retries with backoff, reconnects automatically when Kafka is available

# Test extended outage (2+ minutes)
docker stop kafka ; sleep 120s ; docker start kafka
# Expected: Backoff reaches 30s max, maintains efficient retry until recovery
```

#### Producer Resilience

The producer uses Kafka client-level retry configuration for automatic recovery:

**Supported Producer Properties**:

| Adapter Config Key | Default | Description |
|-------------------|---------|-------------|
| `retries` | `"2147483647"` | Number of retries (infinite by default) |
| `retryBackoffMs` | `"100"` | Backoff between retries in milliseconds |
| `deliveryTimeoutMs` | `"120000"` | Total delivery timeout (2 minutes) |
| `enableIdempotence` | `"true"` | Prevent duplicate messages during retries |

**Example Configuration**:
```yaml
publisher:
  id: publisher
  config:
    type: kafka
    brokers: kafka:9092
    topic: my-topic
    acks: all
    retries: "2147483647"              # Retry indefinitely
    retryBackoffMs: "100"              # 100ms between retries
    deliveryTimeoutMs: "120000"        # 2 min total delivery timeout
    enableIdempotence: "true"          # Prevent duplicates
```

**Behavior**:
- HTTP requests retry automatically for up to 2 minutes when broker is down
- If broker reconnects within timeout: Message delivered successfully
- If timeout expires: HTTP request fails (service stays running)
- Idempotence prevents duplicate messages during retries

## Docker Compose Example

```yaml
version: '3.8'

services:
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      # KRaft mode configuration (no Zookeeper required)
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_NODE_ID: 1
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
    volumes:
      - kafka-data:/var/lib/kafka/data

  adapter:
    build: .
    depends_on:
      - kafka
    environment:
      KAFKA_BROKERS: kafka:9092
      KAFKA_PRODUCER_TOPIC: "adapter.requests"
      KAFKA_CONSUMER_TOPICS: "adapter.responses"
      KAFKA_GROUP_ID: "adapter-consumer"
    volumes:
      - ./config:/app/config
      - ./plugins:/app/plugins

volumes:
  kafka-data:
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to Kafka broker
- Check broker addresses and ports
- Verify Kafka is running: `docker ps | grep kafka`
- Check network connectivity between adapter and Kafka

### Message Not Published

**Problem**: Messages not appearing in topics
- Verify Kafka broker addresses are correct
- Check topic exists: `kafka-topics --list --bootstrap-server localhost:9092`
- Review adapter logs for errors
- Verify producer plugin is loaded correctly

### Consumer Not Receiving Messages

**Problem**: Consumer not receiving any messages
- Verify topics exist and have messages
- Check consumer group ID: `kafka-consumer-groups --list --bootstrap-server localhost:9092`
- Review offset management
- Check auto-commit settings
