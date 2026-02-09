# BAP Kafka Test Messages

This directory contains pre-formatted JSON messages and bash scripts for testing BAP (Buyer App Provider) APIs via Kafka. These scripts act like **BAP Backend**, publishing requests to `bap.*` topics (e.g., `bap.discover`, `bap.select`, etc.) that will be consumed by the **BAP plugin's `bapTxnCaller` module**. You can use these messages directly with Kafka CLI tools or via command-line scripts.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Publish All Messages** - Automatically publishes all JSON files from `example/` directory:
```bash
cd sandbox-kafka/message/bap/test && ./publish-all.sh
```

**🎯 Publish Specific Action Type:**
```bash
# Publish all discover variants (8 messages routed to topic bap.discover)
cd sandbox-kafka/message/bap/test && ./publish-all.sh discover

# Publish a single action family
cd sandbox-kafka/message/bap/test && ./publish-all.sh select
cd sandbox-kafka/message/bap/test && ./publish-all.sh cancel
cd sandbox-kafka/message/bap/test && ./publish-all.sh rating
```

**📝 Publish Single Message:**
```bash
# Discover payloads (topic bap.discover)
cd sandbox-kafka/message/bap/test && ./publish-discover-along-a-route.sh
cd sandbox-kafka/message/bap/test && ./publish-discover-by-evse.sh

# Transaction payloads (topics bap.select, bap.init, …)
cd sandbox-kafka/message/bap/test && ./publish-select.sh
cd sandbox-kafka/message/bap/test && ./publish-init.sh
cd sandbox-kafka/message/bap/test && ./publish-confirm.sh
cd sandbox-kafka/message/bap/test && ./publish-track.sh
```

## Directory Structure

```
message/bap/
├── README.md                     # This file
├── example/                      # JSON message files (discover, select, init, …)
└── test/                         # Bash scripts for publishing
    ├── publish-all.sh            # Publishes every payload (optionally filtered by action)
    ├── publish-common.sh         # Common functions (UUID/timestamp updates + Kafka publish)
    └── publish-*.sh              # Individual message scripts (one per JSON file)
```

## Configuration

Scripts use environment variables for configuration (all optional; sensible defaults are provided):

```bash
export KAFKA_HOST=localhost             # Default: localhost
export KAFKA_PORT=9092                  # Default: 9092
export KAFKA_BOOTSTRAP=localhost:9092   # Default: $KAFKA_HOST:$KAFKA_PORT
```
When the sandbox `docker-compose.yml` is running, the helper scripts automatically
call `kafka-console-producer.sh` inside the `kafka` container via `docker exec`.

## Message Flow

These scripts act like BAP Backend, publishing requests to `bap.*` topics that are consumed by the BAP plugin's `bapTxnCaller` module.

### Phase 1: Discover Flow
1. BAP Backend publishes `discover-*.json` message to topic `bap.discover`
2. ONIX BAP plugin's `bapTxnCaller` consumes and processes
3. BAP plugin routes to Mock CDS for aggregation
4. Response published to `bap.on_discover` topic
5. BAP Backend consumes response from `bap.on_discover` topic

### Phase 2+: Transaction Flow
1. BAP Backend publishes transaction message (select, init, confirm, etc.) to `bap.*` topics
2. ONIX BAP plugin's `bapTxnCaller` consumes and processes
3. BAP plugin routes directly to BPP via HTTP (bypasses CDS)
4. BPP adapter sends callback to BAP plugin's `bapTxnReceiver` at `/bap/receiver/`
5. BAP plugin publishes response to corresponding `bap.on_*` topics
6. BAP Backend consumes response from `bap.on_*` topics

## Prerequisites

### Required Tools
- `jq` - For JSON processing
  - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- `uuidgen` or `python3` - For generating UUIDs (scripts have fallback)
- Docker with Kafka container running (for docker exec method)
- OR Kafka CLI tools installed locally

### Kafka Setup
- Kafka must be running (via docker-compose)
- Topics will be auto-created when first message is published
- Consumer groups are managed by the ONIX plugins

## Using Kafka CLI Tools

You can also publish messages directly using Kafka CLI:

```bash
# Publish a message to a topic
docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bap.discover < message.json
```

## Troubleshooting

### Scripts Fail with "jq: command not found"
Install jq:
```bash
# macOS
brew install jq

# Linux
apt-get install jq
```

### Scripts Fail with "Kafka producer not available"
- Verify Kafka is running: `docker ps | grep kafka`
- Check Kafka is accessible: `docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092`

### Messages Not Being Consumed
- Check consumer is running: `docker ps | grep onix-bap-plugin-kafka`
- Verify topics exist: `docker exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092`
- Check adapter logs: `docker logs onix-bap-plugin-kafka`

