# BPP RabbitMQ Test Messages

This directory contains pre-formatted JSON messages and bash scripts for testing BPP (Buyer Platform Provider) APIs via RabbitMQ. These scripts act like **BPP Backend**, publishing callbacks to `bpp.on_*` routing keys (e.g., `bpp.on_discover`, `bpp.on_select`, etc.) that will be consumed by the **BPP plugin's `bppTxnCaller` module** from `bpp_caller_queue`. You can use these messages directly in the RabbitMQ Management UI or via command-line scripts.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Publish All Messages** - Automatically publishes all JSON files from `example/` directory:
```bash
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh
```

**🎯 Publish Specific Action Type:**
```bash
# Publish on_discover message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_discover

# Publish on_select message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_select

# Publish on_init message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_init

# Publish on_confirm message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_confirm

# Publish on_status message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_status

# Publish on_track message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_track

# Publish on_cancel message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_cancel

# Publish on_update message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_update

# Publish on_rating message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_rating

# Publish on_support message
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-all.sh on_support
```

**📝 Publish Single Message:**
```bash
# Callback messages
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_discover.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_select.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_init.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_confirm.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_status.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_track.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_cancel.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_update.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_rating.sh
cd sandbox/docker/monolithic/rabbitmq/message/bpp/test && ./publish-on_support.sh
```

**How `publish-all.sh` works:**
- ✅ Automatically finds all JSON files in `../example/` directory
- ✅ Extracts action from `context.action` field in each JSON
- ✅ Determines routing key automatically (e.g., `on_discover` → `bpp.on_discover`)
- ✅ Generates unique transaction IDs and message IDs
- ✅ Updates timestamps to current time
- ✅ Publishes each message to RabbitMQ
- ✅ Shows success/failure summary

## Directory Structure

```
message/bpp/
├── README.md                    # This file
├── example/                      # JSON message files
│   ├── on_discover.json
│   ├── on_select.json
│   ├── on_init.json
│   ├── on_confirm.json
│   ├── on_status.json
│   ├── on_track.json
│   ├── on_cancel.json
│   ├── on_update.json
│   ├── on_rating.json
│   └── on_support.json
└── test/                         # Bash scripts for publishing
    ├── publish-all.sh           # Main script - publishes all messages
    ├── publish-common.sh        # Common functions
    ├── publish-on_discover.sh
    ├── publish-on_select.sh
    ├── publish-on_init.sh
    ├── publish-on_confirm.sh
    ├── publish-on_status.sh
    ├── publish-on_track.sh
    ├── publish-on_cancel.sh
    ├── publish-on_update.sh
    ├── publish-on_rating.sh
    └── publish-on_support.sh
```

## Quick Start

### Using Bash Scripts (Recommended)

1. **Navigate to the test directory**:
   ```bash
   cd sandbox/docker/monolithic/rabbitmq/message/bpp/test
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
   ./publish-all.sh on_discover    # Only on_discover message
   ./publish-all.sh on_select       # Only on_select message
   ./publish-all.sh on_init         # Only on_init message
   ./publish-all.sh on_confirm      # Only on_confirm message
   ./publish-all.sh on_status      # Only on_status message
   ./publish-all.sh on_track        # Only on_track message
   ./publish-all.sh on_cancel       # Only on_cancel message
   ./publish-all.sh on_update      # Only on_update message
   ./publish-all.sh on_rating       # Only on_rating message
   ./publish-all.sh on_support      # Only on_support message
   ```

5. **Publish a single message** (using individual scripts):
   ```bash
   ./publish-on_discover.sh
   ./publish-on_select.sh
   ./publish-on_init.sh
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
   - Click on the target queue (e.g., `bpp_caller_queue`)
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
| `publish-on_discover.sh` | On discover callback | `bpp.on_discover` |
| `publish-on_select.sh` | On select callback | `bpp.on_select` |
| `publish-on_init.sh` | On init callback | `bpp.on_init` |
| `publish-on_confirm.sh` | On confirm callback | `bpp.on_confirm` |
| `publish-on_status.sh` | On status callback | `bpp.on_status` |
| `publish-on_track.sh` | On track callback | `bpp.on_track` |
| `publish-on_cancel.sh` | On cancel callback | `bpp.on_cancel` |
| `publish-on_update.sh` | On update callback | `bpp.on_update` |
| `publish-on_rating.sh` | On rating callback | `bpp.on_rating` |
| `publish-on_support.sh` | On support callback | `bpp.on_support` |

**Note**: The `publish-all.sh` script automatically discovers and publishes all JSON files from the `example/` directory, so you don't need to run individual scripts unless you want to test a specific message.

## Message Files and Routing Keys

All JSON message files are located in the `example/` directory. The `publish-all.sh` script automatically reads these files and determines routing keys from the `context.action` field in each JSON file.

| Message File (in `example/`) | Action | Routing Key | Target Queue | Description |
|-------------------------------|-------|-------------|--------------|-------------|
| `on_discover.json` | `on_discover` | `bpp.on_discover` | `bpp_caller_queue` | On discover callback |
| `on_select.json` | `on_select` | `bpp.on_select` | `bpp_caller_queue` | On select callback |
| `on_init.json` | `on_init` | `bpp.on_init` | `bpp_caller_queue` | On init callback |
| `on_confirm.json` | `on_confirm` | `bpp.on_confirm` | `bpp_caller_queue` | On confirm callback |
| `on_status.json` | `on_status` | `bpp.on_status` | `bpp_caller_queue` | On status callback |
| `on_track.json` | `on_track` | `bpp.on_track` | `bpp_caller_queue` | On track callback |
| `on_cancel.json` | `on_cancel` | `bpp.on_cancel` | `bpp_caller_queue` | On cancel callback |
| `on_update.json` | `on_update` | `bpp.on_update` | `bpp_caller_queue` | On update callback |
| `on_rating.json` | `on_rating` | `bpp.on_rating` | `bpp_caller_queue` | On rating callback |
| `on_support.json` | `on_support` | `bpp.on_support` | `bpp_caller_queue` | On support callback |

**Note**: These messages act like BPP Backend publishing callbacks. The BPP Backend publishes to `bpp.on_*` routing keys (callbacks from BPP Backend), and the BPP plugin's `bppTxnCaller` module consumes from `bpp_caller_queue` which is bound to these `bpp.on_*` routing keys.

**How `publish-all.sh` works**:
1. Scans the `example/` directory for all `.json` files
2. Reads the `context.action` field from each JSON file
3. Maps the action to the appropriate routing key (e.g., `on_discover` → `bpp.on_discover`)
4. Generates unique transaction IDs and message IDs for each message
5. Updates timestamps to current time
6. Publishes each message to RabbitMQ with `bpp.on_*` routing keys that the BPP plugin's `bppTxnCaller` consumes

## Configuration

Scripts use environment variables for configuration:

```bash
export RABBITMQ_HOST=rabbitmq       # Default: rabbitmq (cluster service)
export RABBITMQ_PORT=15672          # Default: 15672 (management API)
export RABBITMQ_USER=guest          # Default: guest
export RABBITMQ_PASS=guest          # Default: guest
export EXCHANGE=beckn_exchange      # Default: beckn_exchange
```

Example:
```bash
cd test
RABBITMQ_HOST=192.168.1.100 ./publish-all.sh
# or
RABBITMQ_HOST=192.168.1.100 ./publish-on_select.sh
```

## Message Flow

These scripts act like BPP Backend, publishing callbacks to `bpp.on_*` routing keys that are consumed by the BPP plugin's `bppTxnCaller` module from `bpp_caller_queue`.

### Phase 1: Discover Flow
1. BAP Backend publishes `discover` request with routing key `bap.discover`
2. BAP plugin's `bapTxnCaller` consumes and routes to Mock CDS
3. Mock CDS aggregates and routes to BPP plugin
4. BPP plugin routes to BPP Backend via HTTP
5. BPP Backend processes and publishes `on_discover` callback with routing key `bpp.on_discover`
6. Message goes to `bpp_caller_queue` queue (bound to `bpp.on_*` routing keys)
7. ONIX BPP plugin's `bppTxnCaller` consumes and processes
8. BPP plugin routes callback to BAP plugin
9. BAP plugin publishes response to `bap.on_discover` routing key
10. BAP Backend consumes response from queue bound to `bap.on_discover`

### Phase 2+: Transaction Flow
1. BAP Backend publishes transaction request (select, init, confirm, etc.) with routing key `bap.*`
2. BAP plugin's `bapTxnCaller` consumes and routes directly to BPP plugin via HTTP
3. BPP plugin publishes request to BPP Backend with routing key `bpp.*`
4. BPP Backend processes and publishes callback with routing key `bpp.on_*`
5. Message goes to `bpp_caller_queue` queue (bound to `bpp.on_*` routing keys)
6. ONIX BPP plugin's `bppTxnCaller` consumes and processes
7. BPP plugin routes callback to BAP plugin's `bapTxnReceiver` at `/bap/receiver/`
8. BAP plugin publishes response to corresponding `bap.on_*` routing key
9. BAP Backend consumes response from queue bound to `bap.on_*` routing keys

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
./publish-all.sh on_discover    # Publish on_discover message
./publish-all.sh on_select      # Publish on_select message
./publish-all.sh on_init        # Publish on_init message
```

### Test 3: Single Message Consumption
```bash
cd test
./publish-on_select.sh
```
Then monitor the queue in RabbitMQ Management UI:
- Go to "Queues" → `bpp_caller_queue`
- Watch "Ready" count increase then decrease
- Watch "Unacked" count increase then decrease
- Verify message is consumed successfully by `bppTxnCaller`

### Test 4: Multiple Messages
```bash
cd test
./publish-all.sh
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
- Check consumer is running: `docker-compose ps`
- Verify consumer is connected (Queues → Consumers column)
- Check adapter logs: `docker-compose logs onix-bpp-plugin-rabbitmq`

### Message Format Errors
- Validate JSON syntax: `jq . < message-file.json`
- Check required fields are present in context
- Verify message structure matches expected schema

## Additional Resources

- [RabbitMQ Management UI Guide](../../README.md#rabbitmq-management-ui)
- [Message Flow Documentation](../../README.md#message-flow)
- [Troubleshooting Guide](../../README.md#troubleshooting)

