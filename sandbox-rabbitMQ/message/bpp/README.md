# BPP RabbitMQ Test Messages

This directory contains pre-formatted JSON messages and bash scripts for testing BPP (Buyer Platform Provider) APIs via RabbitMQ. These scripts act like **BPP Backend**, publishing callbacks to `bpp.on_*` routing keys (e.g., `bpp.on_discover`, `bpp.on_select`, etc.) that will be consumed by the **BPP plugin's `bppTxnCaller` module** from `bpp_caller_queue`. You can use these messages directly in the RabbitMQ Management UI or via command-line scripts.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Publish All Messages** - Automatically publishes all JSON files from `example/` directory:
```bash
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh
```

**🎯 Publish Specific Callback Type:**
```bash
# Publish all callbacks (on_* actions) in sequence
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh

# Publish only one callback family (all available actions):
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_discover
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_select
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_init
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_confirm
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_status
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_track
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_cancel
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_update
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_rating
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_support
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh catalog_publish
cd sandbox-rabbitMQ/message/bpp/test && ./publish-all.sh on_catalog_publish
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
    └── publish-common.sh         # Shared helper (UUID/timestamp updates + RabbitMQ publish)
```

## Configuration

Scripts use environment variables for configuration:

```bash
export RABBITMQ_HOST=localhost      # Default: localhost
export RABBITMQ_PORT=15672          # Default: 15672
export RABBITMQ_USER=guest           # Default: guest
export RABBITMQ_PASS=guest           # Default: guest
export EXCHANGE=beckn_exchange      # Default: beckn_exchange
```

## Message Flow

These scripts emulate the BPP Backend callbacks, publishing to `bpp.on_*` routing keys that are consumed by the BPP plugin's `bppTxnCaller` module from `bpp_caller_queue` before being routed to the BAP side.

### Phase 1: Discover Callback Flow
1. BPP Backend produces `on_discover` callback to routing key `bpp.on_discover`
2. Message goes to `bpp_caller_queue` queue (bound to `bpp.on_*` routing keys)
3. ONIX BPP plugin's `bppTxnCaller` consumes, signs and routes to the BAP plugin via HTTP
4. ONIX BAP plugin publishes the response to `bap.on_discover` routing key for BAP Backend consumption

### Phase 2+: Other Callback Flow
1. BPP Backend produces callbacks (`on_select`, `on_init`, `on_confirm`, `on_status`, `on_track`, `on_cancel`, `on_update`, `on_rating`, `on_support`) to the `bpp.on_*` routing keys
2. Messages go to `bpp_caller_queue` queue (bound to `bpp.on_*` routing keys)
3. ONIX BPP plugin's `bppTxnCaller` consumes and forwards to the BAP plugin HTTP receiver
4. ONIX BAP plugin publishes the callback to the matching `bap.on_*` routing key
5. BAP Backend consumes the callback from RabbitMQ

### Catalog Publish Flow
1. BPP Backend produces `catalog_publish` request to routing key `bpp.catalog_publish`
2. Message goes to `bpp_caller_queue` queue (bound to `bpp.catalog_publish` routing key)
3. ONIX BPP plugin's `bppTxnCaller` consumes and routes to discovery indexer via HTTP
4. Discovery indexer processes the catalog and sends `on_catalog_publish` callback
5. ONIX BPP plugin's `bppTxnReceiver` receives the callback at `/bpp/receiver/` and publishes to `bpp.on_catalog_publish` routing key
6. BPP Backend consumes the catalog processing results from RabbitMQ

## Available Message Types

The `publish-all.sh` script supports all 12 message types available in the `example/` directory:

| Action | Routing Key | Example File |
|--------|------------|---------------|
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

All message types are automatically detected from the JSON files' `context.action` field and published to the corresponding RabbitMQ routing key.

## Prerequisites

### Required Tools
- `curl` - For HTTP requests to RabbitMQ Management API
- `jq` - For JSON processing
  - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- `uuidgen` or `python3` - For generating UUIDs (scripts have fallback)

### RabbitMQ Setup
- RabbitMQ must be running with Management Plugin enabled
- Default credentials: guest/guest
- Exchange `beckn_exchange` must exist
- Queue `bpp_caller_queue` must be bound to `bpp.on_*` routing keys

## Using RabbitMQ Management UI

You can also publish messages directly using RabbitMQ Management UI:

1. **Access RabbitMQ Management UI**:
   - URL: `http://localhost:15672`
   - Username: `guest`
   - Password: `guest`

2. **Navigate to Exchanges**:
   - Click "Exchanges" in the top navigation
   - Click on `beckn_exchange`

3. **Scroll to "Publish message" section**

4. **Configure the message**:
   - **Routing key**: Use the routing key specified for each message type (see table above)
   - **Payload**: Copy the entire JSON content from the `example/` directory message file
   - **Properties**: Leave default (or add custom headers if needed)

5. **Click "Publish message"**

6. **Monitor the queue**:
   - Go to "Queues" tab
   - Click on `bpp_caller_queue`
   - Watch the message appear and get consumed

**Note**: When copying JSON from files, remember to update `transaction_id`, `message_id`, and `timestamp` fields with unique values, or use the bash scripts which do this automatically.

## Troubleshooting

### Scripts Fail with "jq: command not found"
Install jq:
```bash
# macOS
brew install jq

# Linux
apt-get install jq
```

### Scripts Fail with "Connection refused"
- Verify RabbitMQ is running: `docker-compose ps`
- Check RabbitMQ Management UI is accessible: `http://localhost:15672`
- Verify network connectivity

### Messages Not Appearing in Queue
- Verify routing key matches queue binding
- Check exchange name is `beckn_exchange`
- Verify queue exists and is bound to exchange with correct routing keys
- Check RabbitMQ logs: `docker-compose logs rabbitmq`

### Messages Not Being Consumed
- Check consumer is running: `docker-compose ps | grep onix-bpp-plugin-rabbitmq`
- Verify consumer is connected (Queues → Consumers column in Management UI)
- Check adapter logs: `docker-compose logs onix-bpp-plugin-rabbitmq`

### Message Format Errors
- Validate JSON syntax: `jq . < message-file.json`
- Check required fields are present in context
- Verify message structure matches expected schema
