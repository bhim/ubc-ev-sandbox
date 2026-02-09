# BAP RabbitMQ Test Messages

This directory contains pre-formatted JSON messages and bash scripts for testing BAP (Buyer App Provider) APIs via RabbitMQ. These scripts act like **BAP Backend**, publishing requests to `bap.*` routing keys (e.g., `bap.discover`, `bap.select`, etc.) that will be consumed by the **BAP plugin's `bapTxnCaller` module** from `bap_caller_queue`. You can use these messages directly in the RabbitMQ Management UI or via command-line scripts.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Publish All Messages** - Automatically publishes all JSON files from `example/` directory:
```bash
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh
```

**🎯 Publish Specific Action Type:**
```bash
# Publish all discover variants (8 messages)
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh discover

# Publish select message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh select

# Publish init message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh init

# Publish confirm message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh confirm

# Publish update message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh update

# Publish track message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh track

# Publish cancel message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh cancel

# Publish rating message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh rating

# Publish support message
cd sandbox-rabbitMQ/message/bap/test && ./publish-all.sh support
```

**📝 Publish Single Message:**
```bash
# Discover messages
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-along-a-route.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-by-evse.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-by-cpo.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-by-station.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-within-boundary.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-within-timerange.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-connector-spec.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-discover-vehicle-spec.sh

# Transaction messages
cd sandbox-rabbitMQ/message/bap/test && ./publish-select.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-init.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-confirm.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-update.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-track.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-cancel.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-rating.sh
cd sandbox-rabbitMQ/message/bap/test && ./publish-support.sh
```

**How `publish-all.sh` works:**
- ✅ Automatically finds all JSON files in `../example/` directory
- ✅ Extracts action from `context.action` field in each JSON
- ✅ Determines routing key automatically (e.g., `discover` → `bap.discover`)
- ✅ Generates unique transaction IDs and message IDs
- ✅ Updates timestamps to current time
- ✅ Publishes each message to RabbitMQ
- ✅ Shows success/failure summary

## Directory Structure

```
message/bap/
├── README.md                    # This file
├── example/                      # JSON message files
│   ├── discover-along-a-route.json
│   ├── discover-by-evse.json
│   ├── discover-by-cpo.json
│   ├── discover-by-station.json
│   ├── discover-within-boundary.json
│   ├── discover-within-timerange.json
│   ├── discover-connector-spec.json
│   ├── discover-vehicle-spec.json
│   ├── select.json
│   ├── init.json
│   ├── confirm.json
│   ├── update.json
│   ├── track.json
│   ├── cancel.json
│   ├── rating.json
│   └── support.json
└── test/                         # Bash scripts for publishing
    ├── publish-all.sh           # Main script - publishes all messages
    ├── publish-common.sh        # Common functions
    ├── publish-discover-along-a-route.sh
    ├── publish-discover-by-evse.sh
    ├── publish-discover-by-cpo.sh
    ├── publish-discover-by-station.sh
    ├── publish-discover-within-boundary.sh
    ├── publish-discover-within-timerange.sh
    ├── publish-discover-connector-spec.sh
    ├── publish-discover-vehicle-spec.sh
    ├── publish-select.sh
    ├── publish-init.sh
    ├── publish-confirm.sh
    ├── publish-update.sh
    ├── publish-track.sh
    ├── publish-cancel.sh
    ├── publish-rating.sh
    └── publish-support.sh
```

## Quick Start

### Using Bash Scripts (Recommended)

1. **Navigate to the test directory**:
   ```bash
   cd sandbox-rabbitMQ/message/bap/test
   ```

2. **Make scripts executable** (if not already):
   ```bash
   chmod +x *.sh
   ```

3. **Publish all messages** (Recommended - automatically finds all JSON files):
   ```bash
   ./publish-all.sh
   ```
   This script automatically:
   - Finds all JSON files in the `../example/` directory
   - Extracts the action from each JSON file's `context.action` field
   - Determines the correct routing key
   - Publishes each message with unique transaction IDs and timestamps

4. **Publish specific action type**:
   ```bash
   ./publish-all.sh discover    # Only discover messages (all 8 variants)
   ./publish-all.sh select      # Only select message
   ./publish-all.sh init        # Only init message
   ./publish-all.sh confirm     # Only confirm message
   ./publish-all.sh update      # Only update message
   ./publish-all.sh track       # Only track message
   ./publish-all.sh cancel      # Only cancel message
   ./publish-all.sh rating      # Only rating message
   ./publish-all.sh support     # Only support message
   ```

5. **Publish a single message** (using individual scripts):
   ```bash
   ./publish-discover-along-a-route.sh
   ./publish-select.sh
   ./publish-init.sh
   ```

### Using RabbitMQ Management UI

1. **Access RabbitMQ Management UI**:
   - URL: `http://localhost:15672`
   - Username: `guest`
   - Password: `guest`

2. **Navigate to Exchanges**:
   - Click "Exchanges" in the top navigation
   - Click on `beckn_exchange`

3. **Scroll to "Publish message" section**

4. **Configure the message**:
   - **Routing key**: Use the routing key specified for each message type (see table below)
   - **Payload**: Copy the entire JSON content from the `example/` directory message file
   - **Properties**: Leave default (or add custom headers if needed)

5. **Click "Publish message"**

6. **Monitor the queue**:
   - Go to "Queues" tab
   - Click on the target queue (e.g., `bap.discover`, `bap.select`, etc.)
   - Watch the message appear and get consumed

**Note**: When copying JSON from files, remember to update `transaction_id`, `message_id`, and `timestamp` fields with unique values, or use the bash scripts which do this automatically.

## Available Scripts

### Main Script

| Script | Description | Usage |
|--------|-------------|-------|
| `publish-all.sh` | **Automatically publishes all JSON files** from `example/` directory. Dynamically determines routing keys from JSON content. | `./publish-all.sh [action]` |

### Individual Scripts

Individual scripts for publishing specific messages (located in `test/` directory):

| Script | Description | Routing Key |
|--------|-------------|-------------|
| `publish-discover-along-a-route.sh` | Discover charging stations along a route | `bap.discover` |
| `publish-discover-by-evse.sh` | Discover by EVSE ID | `bap.discover` |
| `publish-discover-by-cpo.sh` | Discover by CPO (Charge Point Operator) | `bap.discover` |
| `publish-discover-by-station.sh` | Discover by station ID | `bap.discover` |
| `publish-discover-within-boundary.sh` | Discover within geographic boundary | `bap.discover` |
| `publish-discover-within-timerange.sh` | Discover within time range | `bap.discover` |
| `publish-discover-connector-spec.sh` | Discover by connector specifications | `bap.discover` |
| `publish-discover-vehicle-spec.sh` | Discover by vehicle specifications | `bap.discover` |
| `publish-select.sh` | Select a charging offer | `bap.select` |
| `publish-init.sh` | Initialize an order | `bap.init` |
| `publish-confirm.sh` | Confirm an order | `bap.confirm` |
| `publish-update.sh` | Update an order status | `bap.update` |
| `publish-track.sh` | Track an order | `bap.track` |
| `publish-cancel.sh` | Cancel an order | `bap.cancel` |
| `publish-rating.sh` | Submit a rating | `bap.rating` |
| `publish-support.sh` | Request support | `bap.support` |

**Note**: The `publish-all.sh` script automatically discovers and publishes all JSON files from the `example/` directory, so you don't need to run individual scripts unless you want to test a specific message.

## Message Files and Routing Keys

All JSON message files are located in the `example/` directory. The `publish-all.sh` script automatically reads these files and determines routing keys from the `context.action` field in each JSON file.

| Message File (in `example/`) | Action | Routing Key | Target Queue | Description |
|-------------------------------|-------|-------------|--------------|-------------|
| `discover-along-a-route.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover charging stations along a route |
| `discover-by-evse.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover by EVSE ID |
| `discover-by-cpo.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover by CPO (Charge Point Operator) |
| `discover-by-station.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover by station ID |
| `discover-within-boundary.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover within geographic boundary |
| `discover-within-timerange.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover within time range |
| `discover-connector-spec.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover by connector specifications |
| `discover-vehicle-spec.json` | `discover` | `bap.discover` | `bap_caller_queue` | Discover by vehicle specifications |
| `select.json` | `select` | `bap.select` | `bap_caller_queue` | Select a charging offer |
| `init.json` | `init` | `bap.init` | `bap_caller_queue` | Initialize an order |
| `confirm.json` | `confirm` | `bap.confirm` | `bap_caller_queue` | Confirm an order |
| `update.json` | `update` | `bap.update` | `bap_caller_queue` | Update an order status |
| `track.json` | `track` | `bap.track` | `bap_caller_queue` | Track an order |
| `cancel.json` | `cancel` | `bap.cancel` | `bap_caller_queue` | Cancel an order |
| `rating.json` | `rating` | `bap.rating` | `bap_caller_queue` | Submit a rating |
| `support.json` | `support` | `bap.support` | `bap_caller_queue` | Request support |

**Note**: These messages act like BAP Backend publishing requests. The BAP Backend publishes to `bap.*` routing keys (requests from BAP Backend), and the BAP plugin's `bapTxnCaller` module consumes from `bap_caller_queue` which is bound to these `bap.*` routing keys.

**How `publish-all.sh` works**:
1. Scans the `example/` directory for all `.json` files
2. Reads the `context.action` field from each JSON file
3. Maps the action to the appropriate routing key (e.g., `discover` → `bap.discover`)
4. Generates unique transaction IDs and message IDs for each message
5. Updates timestamps to current time
6. Publishes each message to RabbitMQ with `bap.*` routing keys that the BAP plugin's `bapTxnCaller` consumes

## Configuration

Scripts use environment variables for configuration (all optional; sensible defaults are provided):

```bash
export RABBITMQ_HOST=localhost      # Default: localhost
export RABBITMQ_PORT=15672          # Default: 15672
export RABBITMQ_USER=guest          # Default: guest
export RABBITMQ_PASS=guest          # Default: guest
export EXCHANGE=beckn_exchange      # Default: beckn_exchange
```
When the sandbox `docker-compose.yml` is running, the helper scripts automatically
call RabbitMQ Management API via `curl`.

## Message Flow

These scripts act like BAP Backend, publishing requests to `bap.*` routing keys that are consumed by the BAP plugin's `bapTxnCaller` module from `bap_caller_queue`.

### Phase 1: Discover Flow
1. BAP Backend publishes `discover-*.json` message with routing key `bap.discover`
2. Message goes to `bap_caller_queue` queue (bound to `bap.*` routing keys)
3. ONIX BAP plugin's `bapTxnCaller` consumes and processes
4. BAP plugin routes to Mock CDS for aggregation
5. Response published to `bap.on_discover` routing key
6. BAP Backend consumes response from queue bound to `bap.on_discover`

### Phase 2+: Transaction Flow
1. BAP Backend publishes transaction message (select, init, confirm, etc.) to `bap.*` routing keys
2. Message goes to `bap_caller_queue` queue (bound to `bap.*` routing keys)
3. ONIX BAP plugin's `bapTxnCaller` consumes and processes
4. BAP plugin routes directly to BPP via HTTP (bypasses CDS)
5. BPP adapter sends callback to BAP plugin's `bapTxnReceiver` at `/bap/receiver/`
6. BAP plugin publishes response to corresponding `bap.on_*` routing key
7. BAP Backend consumes response from queue bound to `bap.on_*` routing keys

## Prerequisites

### Required Tools
- `curl` - For HTTP requests to RabbitMQ Management API
- `jq` - For JSON processing
  - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- `uuidgen` or `python3` - For generating UUIDs (scripts have fallback)

### RabbitMQ Setup
- RabbitMQ must be running with Management Plugin enabled (via docker-compose)
- Default credentials: guest/guest
- Exchange `beckn_exchange` must exist
- Queue `bap_caller_queue` must be bound to `bap.*` routing keys

## Testing Consumer Behavior

### Test 1: Publish All Messages
```bash
cd test
./publish-all.sh
```
This will automatically publish all JSON files from the `example/` directory. Monitor the output to see which messages were published successfully.

### Test 2: Publish Specific Action Type
```bash
cd test
./publish-all.sh discover    # Publish all 8 discover variants
./publish-all.sh select      # Publish select message
./publish-all.sh init        # Publish init message
```

### Test 3: Single Message Consumption
```bash
cd test
./publish-select.sh
```
Then monitor the queue in RabbitMQ Management UI:
- Go to "Queues" → `bap_caller_queue`
- Watch "Ready" count increase then decrease
- Watch "Unacked" count increase then decrease
- Verify message is consumed successfully by `bapTxnCaller`

### Test 4: Multiple Messages
```bash
cd test
./publish-all.sh discover
```
Monitor queue depths and consumer behavior in Management UI.

### Test 5: Consumer Failure/Recovery
1. Publish messages: `cd test && ./publish-all.sh`
2. Stop consumer: `docker-compose stop onix-bpp-plugin-rabbitmq` (from sandbox directory)
3. Messages accumulate in queues
4. Restart consumer: `docker-compose start onix-bpp-plugin-rabbitmq`
5. Watch messages get consumed

## Troubleshooting

### Scripts Fail with "jq: command not found"
Install jq:
```bash
# macOS
brew install jq

# Linux
apt-get install jq
# or
yum install jq
```

### Scripts Fail with "Connection refused"
- Verify RabbitMQ is running: `docker-compose ps`
- Check RabbitMQ Management UI is accessible: `http://localhost:15672`
- Verify network connectivity

### Messages Not Appearing in Queue
- Verify routing key matches queue name
- Check exchange name is `beckn_exchange`
- Verify queue exists and is bound to exchange
- Check RabbitMQ logs: `docker-compose logs rabbitmq`

### Messages Not Being Consumed
- Check consumer is running: `docker-compose ps | grep onix-bap-plugin-rabbitmq`
- Verify consumer is connected (Queues → Consumers column in Management UI)
- Check adapter logs: `docker-compose logs onix-bap-plugin-rabbitmq`

### Message Format Errors
- Validate JSON syntax: `jq . < message-file.json`
- Check required fields are present in context
- Verify message structure matches expected schema

## Additional Resources

- [RabbitMQ Management UI Guide](../../README.md#rabbitmq-management-ui)
- [Message Flow Documentation](../../README.md#message-flow)
- [Troubleshooting Guide](../../README.md#troubleshooting)
