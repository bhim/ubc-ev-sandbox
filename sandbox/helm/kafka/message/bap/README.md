# BAP Kafka Test Messages

This directory contains pre-formatted JSON messages and bash scripts for testing BAP (Buyer App Provider) APIs via Kafka. These scripts act like **BAP Backend**, publishing requests to `bap.*` topics (e.g., `bap.discover`, `bap.select`, etc.) that will be consumed by the **BAP plugin's `bapTxnCaller` module**. You can use these messages directly with Kafka CLI tools or via command-line scripts.

## Quick Reference

### ▶️ Execute Scripts (Copy & Run Commands)

**🚀 Publish All Messages** - Automatically publishes all JSON files from `example/` directory:
```bash
cd sandbox/helm/kafka/message/bap/test && ./publish-all.sh
```

**🎯 Publish Specific Action Type:**
```bash
# Publish all discover variants (8 messages routed to topic bap.discover)
cd sandbox/helm/kafka/message/bap/test && ./publish-all.sh discover

# Publish a single action family
cd sandbox/helm/kafka/message/bap/test && ./publish-all.sh select
cd sandbox/helm/kafka/message/bap/test && ./publish-all.sh cancel
cd sandbox/helm/kafka/message/bap/test && ./publish-all.sh rating
```

**📝 Publish Single Message:**
```bash
# Discover payloads (topic bap.discover)
cd sandbox/helm/kafka/message/bap/test && ./publish-discover-along-a-route.sh
cd sandbox/helm/kafka/message/bap/test && ./publish-discover-by-evse.sh

# Transaction payloads (topics bap.select, bap.init, …)
cd sandbox/helm/kafka/message/bap/test && ./publish-select.sh
cd sandbox/helm/kafka/message/bap/test && ./publish-init.sh
cd sandbox/helm/kafka/message/bap/test && ./publish-confirm.sh
cd sandbox/helm/kafka/message/bap/test && ./publish-track.sh
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
export KAFKA_HOST=localhost             # Default: localhost (for local Kafka CLI tools)
export KAFKA_PORT=9092                  # Default: 9092 (for local Kafka CLI tools)
export KAFKA_BOOTSTRAP=localhost:9092   # Default: $KAFKA_HOST:$KAFKA_PORT (for local Kafka CLI tools)
export KAFKA_NAMESPACE=ev-charging-sandbox  # Default: ev-charging-sandbox (for Kubernetes)
```

The scripts automatically detect the environment and use the appropriate method:
- **Docker Compose**: If a Docker container named `kafka` is running, scripts use `docker exec`
- **Kubernetes/Helm**: If `kubectl` is available, scripts use `kubectl exec` to access the Kafka pod
- **Local Kafka CLI**: If Kafka CLI tools are installed locally, scripts use them directly

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
- **For Kubernetes/Helm deployments:**
  - `kubectl` configured to access your cluster
  - Kafka pod running in the cluster (default namespace: `ev-charging-sandbox`)
- **For Docker Compose deployments:**
  - Docker with Kafka container running
- **OR** Kafka CLI tools installed locally

### Kafka Setup
- **Kubernetes/Helm**: Kafka must be deployed and running in your cluster
  - Check: `kubectl get pods -n ev-charging-sandbox -l component=kafka`
- **Docker Compose**: Kafka container must be running
  - Check: `docker ps | grep kafka`
- Topics will be auto-created when first message is published
- Consumer groups are managed by the ONIX plugins

## Using Kafka CLI Tools

You can also publish messages directly using Kafka CLI:

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

**For Docker Compose:**
- Check consumer is running: `docker ps | grep onix-bap-plugin-kafka`
- Verify topics exist: `docker exec kafka kafka-topics.sh --list --bootstrap-server localhost:9092`
- Check adapter logs: `docker logs onix-bap-plugin-kafka`

