# BPP Kafka Test Messages

This directory contains pre-formatted JSON messages and bash scripts for testing BPP (Buyer Platform Provider) APIs via Kafka. These scripts act like **BPP Backend**, publishing requests to `bpp.*` topics (e.g., `bpp.discover`, `bpp.select`, etc.) that will be consumed by the **BPP plugin's `bppTxnCaller` module**. You can use these messages directly with Kafka CLI tools or via command-line scripts.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Publish All Messages** - Automatically publishes all JSON files from `example/` directory:
```bash
cd sandbox-kafka/message/bpp/test && ./publish-all.sh
```

**🎯 Publish Specific Callback Type:**
```bash
# Publish all callbacks (on_* actions) in sequence
cd sandbox-kafka/message/bpp/test && ./publish-all.sh

# Publish only one callback family (all available actions):
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_discover
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_select
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_init
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_confirm
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_status
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_track
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_cancel
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_update
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_rating
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_support
cd sandbox-kafka/message/bpp/test && ./publish-all.sh catalog_publish
cd sandbox-kafka/message/bpp/test && ./publish-all.sh on_catalog_publish
```

> The `publish-all.sh` script automatically handles all example files in the `example/` directory.
> Use the action filter to publish specific callback types, or omit the filter to publish all callbacks.

## Directory Structure

```
message/bpp/
├── README.md                     # This file
├── example/                      # JSON message payloads (12 message types)
│   ├── on_discover.json          # Discover callback
│   ├── on_select.json            # Select callback
│   ├── on_init.json              # Init callback
│   ├── on_confirm.json            # Confirm callback
│   ├── on_status.json             # Status callback
│   ├── on_track.json              # Track callback
│   ├── on_cancel.json             # Cancel callback
│   ├── on_update.json             # Update callback
│   ├── on_rating.json             # Rating callback
│   ├── on_support.json            # Support callback
│   ├── catalog_publish.json       # Catalog publish request
│   └── on_catalog_publish.json    # Catalog publish callback
└── test/
    ├── publish-all.sh            # Publishes every payload (optionally filtered by action)
    └── publish-common.sh         # Shared helper (UUID/timestamp updates + Kafka publish)
```

## Configuration

Scripts use environment variables for configuration:

```bash
export KAFKA_HOST=localhost      # Default: localhost
export KAFKA_PORT=9092           # Default: 9092
export KAFKA_BOOTSTRAP=localhost:9092  # Default: localhost:9092
```

## Message Flow

These scripts emulate the BPP Backend callbacks, publishing to `bpp.on_*` topics that are consumed by the BPP plugin's `bppTxnCaller` module before being routed to the BAP side.

### Phase 1: Discover Callback Flow
1. BPP Backend produces `on_discover` callback to topic `bpp.on_discover`
2. ONIX BPP plugin's `bppTxnCaller` consumes, signs and routes to the BAP plugin via HTTP
3. ONIX BAP plugin publishes the response to `bap.on_discover` for BAP Backend consumption

### Phase 2+: Other Callback Flow
1. BPP Backend produces callbacks (`on_select`, `on_init`, `on_confirm`, `on_status`, `on_track`, `on_cancel`, `on_update`, `on_rating`, `on_support`) to the `bpp.on_*` topics
2. ONIX BPP plugin's `bppTxnCaller` consumes and forwards to the BAP plugin HTTP receiver
3. ONIX BAP plugin publishes the callback to the matching `bap.on_*` topic
4. BAP Backend consumes the callback from Kafka

### Catalog Publish Flow
1. BPP Backend produces `catalog_publish` request to topic `bpp.catalog_publish`
2. ONIX BPP plugin's `bppTxnCaller` consumes and routes to discovery indexer via HTTP
3. Discovery indexer processes the catalog and sends `on_catalog_publish` callback
4. ONIX BPP plugin's `bppTxnReceiver` receives the callback and publishes to `bpp.on_catalog_publish`
5. BPP Backend consumes the catalog processing results from Kafka

## Available Message Types

The `publish-all.sh` script supports all 12 message types available in the `example/` directory:

| Action | Topic | Example File |
|--------|-------|---------------|
| `on_discover` | `bpp.on_discover` | `on_discover.json` |
| `on_select` | `bpp.on_select` | `on_select.json` |
| `on_init` | `bpp.on_init` | `on_init.json` |
| `on_confirm` | `bpp.on_confirm` | `on_confirm.json` |
| `on_status` | `bpp.on_status` | `on_status.json` |
| `on_track` | `bpp.on_track` | `on_track.json` |
| `on_cancel` | `bpp.on_cancel` | `on_cancel.json` |
| `on_update` | `bpp.on_update` | `on_update.json` |
| `on_rating` | `bpp.on_rating` | `on_rating.json` |
| `on_support` | `bpp.on_support` | `on_support.json` |
| `catalog_publish` | `bpp.catalog_publish` | `catalog_publish.json` |
| `on_catalog_publish` | `bpp.on_catalog_publish` | `on_catalog_publish.json` |

All message types are automatically detected from the JSON files' `context.action` field and published to the corresponding Kafka topic.

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
# Publish a callback to topic bpp.on_select
docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bpp.on_select < example/on_select.json

# Publish other callbacks (replace on_select with any callback type)
docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bpp.on_init < example/on_init.json

docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bpp.on_confirm < example/on_confirm.json

docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bpp.catalog_publish < example/catalog_publish.json

docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bpp.on_catalog_publish < example/on_catalog_publish.json
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
- Check consumer is running: `docker ps | grep onix-bpp-plugin-kafka`
- Verify topics exist: `docker exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092`
- Check adapter logs: `docker logs onix-bpp-plugin-kafka`

