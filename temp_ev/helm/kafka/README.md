# Helm Chart - Kafka Integration (KRaft Mode)

Helm chart for deploying onix-adapter with Kafka in KRaft (Kafka Raft) mode. This configuration uses Kafka without Zookeeper, leveraging the newer KRaft consensus protocol.

## Architecture Overview

Deploy onix-adapter with Kafka message broker using Helm charts. In this architecture:
- **Kafka**: Runs in KRaft mode (no Zookeeper required)
- **Redis**: Used for caching and state management
- **Onix-Adapter**: BAP/BPP plugin consuming/producing messages via Kafka
- **Message-Based Communication**: Uses Kafka topics for async message processing

## Prerequisites

- Kubernetes cluster (v1.20+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Access to onix-adapter Docker images:
  - `manendrapalsingh/onix-bap-plugin-kafka:latest`
  - `manendrapalsingh/onix-bpp-plugin-kafka:latest`

## Quick Start

### Install BAP Adapter with Kafka

```bash
# Install with default values
helm install onix-bap-kafka ./helm/kafka -f ./helm/kafka/values-bap.yaml

# Or install with custom values
helm install onix-bap-kafka ./helm/kafka -f ./helm/kafka/values-bap.yaml --set image.tag=v1.0.0
```

### Install BPP Adapter with Kafka

```bash
# Install with default values
helm install onix-bpp-kafka ./helm/kafka -f ./helm/kafka/values-bpp.yaml

# Or install with custom values
helm install onix-bpp-kafka ./helm/kafka -f ./helm/kafka/values-bpp.yaml --set image.tag=v1.0.0
```

## Configuration

### Kafka KRaft Mode

The chart configures Kafka to run in KRaft mode (no Zookeeper):

```yaml
kafka:
  enabled: true
  processRoles: "broker,controller"
  service:
    port: 9092
    targetPort: 9092
    controllerPort: 9093

kraft:
  enabled: true
  nodeId: 1
```

### Key Features

- **No Zookeeper**: Uses KRaft consensus protocol
- **Simplified Deployment**: Single Kafka deployment handles both broker and controller roles
- **Better Performance**: KRaft mode offers improved performance and scalability

## Service Endpoints

Once deployed, services are accessible via Kubernetes services:

- **Kafka Broker**: `onix-kafka-kafka:9092`
- **Kafka Controller**: `onix-kafka-kafka:9093`
- **BAP Service**: `onix-kafka-bap-service:8001`
- **BPP Service**: `onix-kafka-bpp-service:8002`

## Upgrading

```bash
helm upgrade onix-bap-kafka ./helm/kafka -f ./helm/kafka/values-bap.yaml
```

## Uninstalling

```bash
helm uninstall onix-bap-kafka
helm uninstall onix-bpp-kafka
```

