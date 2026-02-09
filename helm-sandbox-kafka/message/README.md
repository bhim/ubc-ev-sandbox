# Kafka Test Messages - Helm Kafka Sandbox

This directory contains pre-formatted JSON messages and bash scripts for testing the ONIX Kafka adapters deployed via Helm in the Kubernetes sandbox environment.

## Overview

These test messages are configured for Kafka message publishing with Kubernetes service names. Messages are published to Kafka topics that are consumed by the ONIX adapters' queue consumers (`bapTxnCaller` and `bppTxnCaller`).

## Directory Structure

```
message/
├── README.md                     # This file
├── bap/                          # BAP (Buyer App Provider) test messages
│   ├── README.md                # BAP-specific documentation
│   ├── example/                 # JSON message files
│   │   ├── discover-*.json     # Discover request variants
│   │   ├── select.json         # Select request
│   │   ├── init.json           # Init request
│   │   ├── confirm.json        # Confirm request
│   │   └── ...                 # Other action requests
│   └── test/                    # Test scripts
│       ├── publish-common.sh   # Common functions for Kafka publishing
│       ├── publish-all.sh      # Publish all messages
│       └── publish-*.sh        # Individual publish scripts
└── bpp/                          # BPP (Buyer Platform Provider) test messages
    ├── README.md                # BPP-specific documentation
    ├── example/                 # JSON message files
    │   ├── on_discover.json    # On discover response
    │   ├── on_select.json      # On select response
    │   └── ...                 # Other response messages
    └── test/                    # Test scripts
        ├── publish-common.sh   # Common functions for Kafka publishing
        └── publish-all.sh      # Publish all messages
```

## Quick Start

### Prerequisites

1. **Deploy Services**: Deploy BAP and BPP Kafka adapters using Helm
   ```bash
   cd helm-sandbox-kafka
   ./deploy-all.sh
   ```

2. **Install Required Tools**:
   ```bash
   # macOS
   brew install jq kubectl
   
   # Linux
   apt-get install jq kubectl
   ```

3. **Verify Kafka is Running**:
   ```bash
   kubectl get pods -n ev-charging-sandbox -l component=kafka
   ```

### Publish BAP Messages

```bash
# Publish all BAP messages
cd helm-sandbox-kafka/message/bap/test
./publish-all.sh

# Publish specific action type
./publish-all.sh discover
./publish-all.sh select

# Publish single message
./publish-discover-by-station.sh
./publish-select.sh
```

### Publish BPP Messages

```bash
# Publish all BPP messages
cd helm-sandbox-kafka/message/bpp/test
./publish-all.sh

# Publish specific message
# (BPP messages are typically responses, so individual scripts may not be needed)
```

## Configuration

Test scripts use environment variables that can be customized:

```bash
# Kafka configuration
export KAFKA_HOST=localhost             # For local Kafka CLI tools
export KAFKA_PORT=9092                 # For local Kafka CLI tools
export KAFKA_BOOTSTRAP=localhost:9092   # For local Kafka CLI tools
export KAFKA_NAMESPACE=ev-charging-sandbox  # Kubernetes namespace (default)

# The scripts automatically detect the environment:
# - Docker Compose: Uses docker exec if Kafka container is running
# - Kubernetes/Helm: Uses kubectl exec to access Kafka pod
# - Local: Uses Kafka CLI tools if installed
```

## Message Flow

### Service Discovery Flow (Phase 1)

1. **BAP Backend** → Publishes `discover` request to Kafka topic `bap.discover`
2. **ONIX BAP Plugin** → `bapTxnCaller` consumes message, routes to **Mock CDS** via HTTP
3. **Mock CDS** → Broadcasts discover to all registered BPPs
4. **ONIX BPP Plugin** → Receives discover from CDS, publishes to Kafka topic `bpp.discover`
5. **Mock BPP Kafka** → Consumes `bpp.discover`, processes, publishes `on_discover` response
6. **ONIX BPP Plugin** → Routes `on_discover` response to **Mock CDS** via HTTP
7. **Mock CDS** → Aggregates responses, sends to **ONIX BAP Plugin**
8. **ONIX BAP Plugin** → Publishes aggregated response to Kafka topic `bap.on_discover`
9. **Mock BAP Kafka** → Consumes `bap.on_discover` callback

### Transaction Flow (Phase 2+)

1. **BAP Backend** → Publishes transaction message (select, init, confirm, etc.) to `bap.*` topics
2. **ONIX BAP Plugin** → `bapTxnCaller` consumes message, routes directly to **ONIX BPP Plugin** (bypasses CDS)
3. **ONIX BPP Plugin** → Publishes to Kafka topics `bpp.*` (to BPP Backend)
4. **Mock BPP Kafka** → Consumes request, processes, publishes response
5. **ONIX BPP Plugin** → Routes callback to **ONIX BAP Plugin** via HTTP
6. **ONIX BAP Plugin** → Publishes callback to Kafka topics `bap.on_*`
7. **Mock BAP Kafka** → Consumes callback

## Kafka Topic Structure

### BAP Topics (Request Topics)
- `bap.discover` - Discovery requests
- `bap.select` - Selection requests
- `bap.init` - Initialization requests
- `bap.confirm` - Confirmation requests
- `bap.status` - Status requests
- `bap.track` - Tracking requests
- `bap.cancel` - Cancellation requests
- `bap.update` - Update requests
- `bap.rating` - Rating requests
- `bap.support` - Support requests

### BAP Topics (Callback Topics)
- `bap.on_discover` - Discovery responses
- `bap.on_select` - Selection responses
- `bap.on_init` - Initialization responses
- `bap.on_confirm` - Confirmation responses
- `bap.on_status` - Status responses
- `bap.on_track` - Tracking responses
- `bap.on_cancel` - Cancellation responses
- `bap.on_update` - Update responses
- `bap.on_rating` - Rating responses
- `bap.on_support` - Support responses

### BPP Topics (Request Topics)
- `bpp.discover` - Discovery requests (from CDS)
- `bpp.select` - Selection requests
- `bpp.init` - Initialization requests
- `bpp.confirm` - Confirmation requests
- `bpp.status` - Status requests
- `bpp.track` - Tracking requests
- `bpp.cancel` - Cancellation requests
- `bpp.update` - Update requests
- `bpp.rating` - Rating requests
- `bpp.support` - Support requests

### BPP Topics (Callback Topics)
- `bpp.on_discover` - Discovery responses
- `bpp.on_select` - Selection responses
- `bpp.on_init` - Initialization responses
- `bpp.on_confirm` - Confirmation responses
- `bpp.on_status` - Status responses
- `bpp.on_track` - Tracking responses
- `bpp.on_cancel` - Cancellation responses
- `bpp.on_update` - Update responses
- `bpp.on_rating` - Rating responses
- `bpp.on_support` - Support responses

## Message Adaptation

The test scripts automatically adapt messages for Kubernetes:

1. **Dynamic IDs**: Generates new `transaction_id` and `message_id` for each request
2. **Timestamps**: Updates `timestamp` to current UTC time
3. **Service Names**: Uses Kubernetes service names in message context (if needed)

## Using Messages Directly with Kafka CLI

You can also publish messages directly using Kafka CLI tools:

**Kubernetes/Helm:**
```bash
# Find Kafka pod
KAFKA_POD=$(kubectl get pod -n ev-charging-sandbox -l component=kafka -o jsonpath='{.items[0].metadata.name}')

# Publish a message to a topic
cat message.json | kubectl exec -i -n ev-charging-sandbox $KAFKA_POD -- \
  kafka-console-producer --bootstrap-server localhost:9092 --topic bap.discover
```

**Docker Compose:**
```bash
# Publish a message to a topic
docker exec -i kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic bap.discover < message.json
```

## Monitoring Messages

### Using Kafka UI

1. **Port forward Kafka UI**:
   ```bash
   kubectl port-forward svc/onix-kafka-ui 8080:8080 -n ev-charging-sandbox
   ```

2. **Open Kafka UI**: http://localhost:8080

3. **Browse topics and messages**:
   - View all topics
   - Browse messages in each topic
   - Monitor consumer groups
   - View cluster metrics

### Using kubectl

```bash
# List all topics
kubectl exec -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=kafka -o jsonpath='{.items[0].metadata.name}') -- \
  kafka-topics --list --bootstrap-server localhost:9092

# Consume messages from a topic
kubectl exec -n ev-charging-sandbox \
  $(kubectl get pod -n ev-charging-sandbox -l component=kafka -o jsonpath='{.items[0].metadata.name}') -- \
  kafka-console-consumer --bootstrap-server localhost:9092 --topic bap.discover --from-beginning
```

## Available Test Messages

### BAP Messages (Outgoing Requests)

- **Discover**: 8 variants (by station, EVSE, CPO, route, boundary, timerange, connector spec, vehicle spec)
- **Select**: Order selection request
- **Init**: Order initialization request
- **Confirm**: Order confirmation request
- **Update**: Order update request
- **Track**: Order tracking request
- **Cancel**: Order cancellation request
- **Rating**: Rating submission request
- **Support**: Support request

### BPP Messages (Outgoing Responses)

- **on_discover**: Discovery response
- **on_select**: Selection response
- **on_init**: Initialization response
- **on_confirm**: Confirmation response
- **on_status**: Status update response
- **on_track**: Tracking response
- **on_cancel**: Cancellation response
- **on_update**: Update response
- **on_rating**: Rating response
- **on_support**: Support response

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

**For Kubernetes/Helm:**
- Verify kubectl is configured: `kubectl cluster-info`
- Check Kafka pod is running: `kubectl get pods -n ev-charging-sandbox -l component=kafka`
- Verify namespace is correct (set `KAFKA_NAMESPACE` if different from default)
- Check Kafka pod logs: `kubectl logs -n ev-charging-sandbox -l component=kafka`

**For Docker Compose:**
- Verify Kafka is running: `docker ps | grep kafka`
- Check Kafka is accessible: `docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092`

**For Local Kafka CLI:**
- Verify Kafka CLI tools are installed: `which kafka-console-producer`
- Check Kafka is accessible: `kafka-broker-api-versions --bootstrap-server localhost:9092`

### Messages Not Being Consumed

**For Kubernetes/Helm:**
- Check consumer pods are running: `kubectl get pods -n ev-charging-sandbox -l component=bap`
- Verify topics exist: `kubectl exec -n ev-charging-sandbox $(kubectl get pod -n ev-charging-sandbox -l component=kafka -o jsonpath='{.items[0].metadata.name}') -- kafka-topics --list --bootstrap-server localhost:9092`
- Check adapter logs: `kubectl logs -n ev-charging-sandbox -l component=bap`

**For Docker Compose (if using docker-compose instead of Helm):**
- Check consumer is running: `docker ps | grep onix-bap-service` (or container name used in docker-compose)
- Verify topics exist: `docker exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092`
- Check adapter logs: `docker logs <container-name>` (use actual container name from docker-compose)

### Connection Issues

- **Kafka pod not found**: Ensure Kafka is deployed and running (`kubectl get pods -n ev-charging-sandbox -l component=kafka`)
- **Topic creation fails**: Check Kafka pod logs for errors
- **Messages not appearing**: Verify consumer groups are configured correctly

## Differences from HTTP/REST Messages

These messages are adapted from the HTTP/REST message directory (`helm-sendbox/message/`) with the following changes:

1. **Transport**: Uses Kafka topics instead of HTTP/REST endpoints
2. **Service Names**: Updated to use Kubernetes service names for internal routing
3. **Testing**: Uses Kafka producer scripts instead of curl-based scripts
4. **Message Flow**: Asynchronous via Kafka topics instead of synchronous HTTP requests

The JSON message structure remains the same, only the transport mechanism differs.

## Additional Resources

- **BAP Documentation**: See `bap/README.md` for detailed BAP testing guide
- **BPP Documentation**: See `bpp/README.md` for detailed BPP testing guide
- **Deployment Guide**: See `../../README.md` for Helm deployment instructions
- **Kafka Documentation**: https://kafka.apache.org/documentation/
