# Onix-Adapter Integration Guide

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Supported-blue.svg)](https://kubernetes.io/)

**A comprehensive integration guide for deploying and configuring the onix-adapter with BAP and BPP applications**

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Integration Methods](#integration-methods)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Overview

This repository provides **comprehensive guides** for integrating the **[onix-adapter](https://github.com/Beckn-One/beckn-onix)** (also known as Beckn-ONIX) with **BAP (Buyer App Provider)** and **BPP (Buyer App Provider)** applications using various deployment methods, architecture patterns, and communication protocols.

### What is Onix-Adapter?

The **onix-adapter** is a production-ready, plugin-based middleware adapter for the Beckn Protocol. It acts as a protocol adapter between Beckn Application Platforms (BAPs) and Beckn Provider Platforms (BPPs), ensuring secure, validated, and compliant message exchange across various commerce networks.

### Key Concepts

- **BAP (Beckn Application Platform)**: Buyer-side applications that help users search for and purchase products/services (e.g., consumer apps, aggregators)
- **BPP (Beckn Provider Platform)**: Seller-side platforms that provide products/services (e.g., merchant platforms, service providers)
- **Onix-Adapter**: Middleware that handles protocol compliance, message signing, validation, and routing between BAPs and BPPs

---

## Features

### 🚀 Multiple Deployment Methods

- **Docker Compose**: Quick local development and testing setup
- **Complete Sandbox**: Pre-configured full environment with ONIX adapters, mock services, and infrastructure
- **Standalone Adapters**: Deploy only ONIX adapters for integration with your own services
- **Helm Charts**: Production-ready Kubernetes deployments
- **Container-Based**: Pre-built Docker images from GitHub Container Registry

### 🏗️ Flexible Architecture Patterns

- **Monolithic**: Single container/service for all components - ideal for development and small-scale deployments
- **Microservice**: Separate containers for independent scaling - ideal for production environments

### 📡 Multiple Communication Protocols

- **REST API**: Synchronous HTTP/REST communication for real-time interactions
- **RabbitMQ**: Asynchronous message queue for decoupled systems with guaranteed delivery
- **Apache Kafka**: High-throughput event streaming for large-scale, event-driven architectures

### 🔐 Enterprise-Ready

- **Ed25519 Digital Signatures**: Cryptographically secure message signing and validation
- **JSON Schema Validation**: Ensures protocol compliance
- **Redis Caching**: Performance optimization
- **Configurable Routing**: YAML-based routing rules

### 📊 Production Features

- **Health Checks**: Liveness and readiness probes
- **Structured Logging**: JSON-formatted logs with transaction tracking
- **Environment-Specific Configs**: Separate configurations for development, staging, and production

---

## Quick Start

### Prerequisites

#### For Docker Integration
- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- Access to onix-adapter Docker images:
  - `manendrapalsingh/onix-bap-plugin:latest`
  - `manendrapalsingh/onix-bpp-plugin:latest`

#### For Helm Chart Integration
- Kubernetes cluster (v1.20+)
- Helm 3.x installed
- kubectl configured to access your cluster

### Recommended Starting Point

#### Option 1: Complete Sandbox Environment (Recommended for Testing)

Start with the **Complete Sandbox** for a full testing environment with all services:

**Docker Sandbox Environments:**

**Monolithic API Sandbox** (REST API communication):
```bash
# Navigate to the monolithic API sandbox directory
cd sandbox/docker/api/monolithic

# Start all services (ONIX adapters, mock services, Redis)
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

For detailed instructions, see: **[Monolithic API Sandbox Guide](./sandbox/docker/api/monolithic/README.md)**

**RabbitMQ Sandbox** (Message queue integration):
```bash
# Navigate to the RabbitMQ sandbox directory
cd sandbox/docker/rabbitmq

# Start all services (ONIX adapters, RabbitMQ, mock services, Redis)
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

For detailed instructions, see: **[RabbitMQ Sandbox Guide](./sandbox/docker/rabbitmq/README.md)**

**Kafka Sandbox** (Event streaming integration):
```bash
# Navigate to the Kafka sandbox directory
cd sandbox/docker/kafka

# Start all services (ONIX adapters, Kafka, mock services, Redis)
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

For detailed instructions, see: **[Kafka Sandbox Guide](./sandbox/docker/kafka/README.md)**

**Microservice API Sandbox** (Single adapter with endpoint-based routing):
```bash
# Navigate to the microservice API sandbox directory
cd sandbox/docker/api/microservice

# Start all services (ONIX adapters, multiple mock services, Redis)
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

For detailed instructions, see: **[Microservice API Sandbox Guide](./sandbox/docker/api/microservice/README.md)**

**Helm Sandbox Environments (Kubernetes):**

**Monolithic API Sandbox** (Kubernetes deployment):
```bash
# Navigate to the monolithic API sandbox directory
cd sandbox/helm/api/monolithic

# Deploy BAP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-bap ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-bpp ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-bap-1 ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-bap-2 ../../../../helm/api/monolithic \
  -f ../../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods
kubectl get pods -n ev-charging-sandbox  # If using namespace
kubectl get svc
```

For detailed instructions, see: **[Monolithic API Helm Sandbox Guide](./sandbox/helm/api/monolithic/README.md)**

**Microservice API Sandbox** (Kubernetes deployment):
```bash
# Navigate to the microservice API sandbox directory
cd sandbox/helm/api/microservice

# Deploy BAP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-bap ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-bpp ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-bap-1 ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-bap-2 ../../../../helm/api/microservice \
  -f ../../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods
kubectl get pods -n ev-charging-sandbox  # If using namespace
kubectl get svc
```

For detailed instructions, see: **[Microservice API Helm Sandbox Guide](./sandbox/helm/api/microservice/README.md)**

**Kafka Sandbox** (Kubernetes deployment):
```bash
# Navigate to the Kafka sandbox directory
cd sandbox/helm/kafka

# Deploy BAP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-kafka-bap-1 ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-kafka-bap-2 ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods
kubectl get pods -n ev-charging-sandbox  # If using namespace
kubectl get svc
```

For detailed instructions, see: **[Kafka Helm Sandbox Guide](./sandbox/helm/kafka/README.md)**

**RabbitMQ Sandbox** (Kubernetes deployment):
```bash
# Navigate to the RabbitMQ sandbox directory
cd sandbox/helm/rabbitmq

# Deploy BAP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Install multiple instances with different release names
helm install ev-charging-rabbitmq-bap-1 ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

helm install ev-charging-rabbitmq-bap-2 ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox

# Check deployment status
kubectl get pods
kubectl get pods -n ev-charging-sandbox  # If using namespace
kubectl get svc
```

**Note**: 
- Use `helm upgrade --install` for idempotent deployments (installs if release doesn't exist, upgrades if it does)
- All Helm deployments support the `--namespace` flag to deploy to a specific namespace
- Use `--create-namespace` to automatically create the namespace if it doesn't exist
- To install multiple instances in the same namespace, use different release names (e.g., `ev-charging-bap-1`, `ev-charging-bap-2`)

For detailed instructions, see: **[RabbitMQ Helm Sandbox Guide](./sandbox/helm/rabbitmq/README.md)**

#### Option 2: Standalone ONIX Adapters

For deploying only the ONIX adapters without mock services:

**Monolithic Architecture**:
```bash
# Navigate to the monolithic API directory
cd docker/api/monolithic

# Start BAP services
docker-compose -f docker-compose-onix-bap-plugin.yml up -d

# Start BPP services (in a separate terminal)
docker-compose -f docker-compose-onix-bpp-plugin.yml up -d

# Verify services are running
docker-compose -f docker-compose-onix-bap-plugin.yml ps
docker-compose -f docker-compose-onix-bpp-plugin.yml ps
```

For detailed instructions, see: **[Monolithic API Integration Guide](./docker/api/monolithic/README.md)**

**Microservice Architecture**:
```bash
# Navigate to the microservice API directory
cd docker/api/microservice

# Start BAP services
docker-compose -f docker-compose-onix-bap-plugin.yml up -d

# Start BPP services (in a separate terminal)
docker-compose -f docker-compose-onix-bpp-plugin.yml up -d

# Verify services are running
docker-compose -f docker-compose-onix-bap-plugin.yml ps
docker-compose -f docker-compose-onix-bpp-plugin.yml ps
```

For detailed instructions, see: **[Microservice API Integration Guide](./docker/api/microservice/README.md)**

---

## Architecture

### Integration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Integration Architecture                  │
└─────────────────────────────────────────────────────────────┘

Phase 1: Discovery (Aggregation via CDS)
┌────────┐         ┌──────────────┐         ┌─────────┐
│  BAP   │ ──────> │ ONIX BAP     │ ──────> │   CDS   │
│        │         │ Caller       │         │         │
└────────┘         └──────────────┘         └────┬────┘
                                                  │
                                    ┌─────────────┴─────────────┐
                                    │   Aggregates from BPPs    │
                                    └─────────────┬─────────────┘
                                                  │
┌────────┐         ┌──────────────┐         ┌────▼────┐
│  BAP   │ <────── │ ONIX BAP     │ <────── │   CDS   │
│        │         │ Receiver     │         │         │
└────────┘         └──────────────┘         └─────────┘

Phase 2+: Direct BPP Communication
┌────────┐         ┌──────────────┐         ┌──────────────┐         ┌────────┐
│  BAP   │ ──────> │ ONIX BAP     │ ──────> │ ONIX BPP     │ ──────> │  BPP   │
│        │         │ Caller       │         │ Receiver     │         │        │
└────────┘         └──────────────┘         └──────────────┘         └────┬───┘
                                                                            │
┌────────┐         ┌──────────────┐         ┌──────────────┐         ┌────▼───┐
│  BAP   │ <────── │ ONIX BAP     │ <────── │ ONIX BPP     │ <────── │  BPP   │
│        │         │ Receiver     │         │ Caller       │         │        │
└────────┘         └──────────────┘         └──────────────┘         └────────┘
```

### Core Components

1. **Transaction Modules**
   - `bapTxnReceiver`: Receives callback responses at BAP
   - `bapTxnCaller`: Sends requests from BAP to BPP/CDS
   - `bppTxnReceiver`: Receives requests at BPP
   - `bppTxnCaller`: Sends responses from BPP to BAP/CDS

2. **Processing Pipeline**
   - Signature validation (`validateSign`)
   - Routing determination (`addRoute`)
   - Schema validation (`validateSchema`)
   - Message signing (`sign`)

3. **Plugins**
   - Cache (Redis-based)
   - Router (YAML-based routing)
   - Signer/SignValidator (Ed25519)
   - SchemaValidator (JSON schema validation)
   - KeyManager (HashiCorp Vault or simple key management)
   - Consumer (Kafka/RabbitMQ message consumption)
   - Publisher (Kafka/RabbitMQ message publishing)

---

## Integration Methods

### 1. Docker Container Integration

#### 1.0 Sandbox Environments
- **[1.0.1 Monolithic API Sandbox](./sandbox/docker/api/monolithic/README.md)** ✅ **Ready** - Full testing environment with monolithic architecture (REST API)
- **[1.0.2 Microservice API Sandbox](./sandbox/docker/api/microservice/README.md)** ✅ **Ready** - Full testing environment with microservice architecture (REST API)
- **[1.0.3 RabbitMQ Sandbox](./sandbox/docker/rabbitmq/README.md)** ✅ **Ready** - Full testing environment with RabbitMQ message queue integration
- **[1.0.4 Kafka Sandbox](./sandbox/docker/kafka/README.md)** ✅ **Ready** - Full testing environment with Apache Kafka event streaming integration
- [1.0.5 Standalone Mock Services](./sandbox/) - Individual mock service deployments (BAP/BPP for REST API, Kafka, and RabbitMQ)

#### 1.1 Monolithic Architecture
- **[1.1.1 API Integration](./docker/api/monolithic/README.md)** ✅ **Ready** - Standalone ONIX adapters

#### 1.2 Microservice Architecture
- **[1.2.1 API Integration](./docker/api/microservice/README.md)** ✅ **Ready** - Standalone ONIX adapters with endpoint-based routing

#### 1.3 Message Queue & Event Streaming (Works for both architectures)
- **[1.3.1 RabbitMQ Integration](./docker/rabbitmq/README.md)** ✅ **Ready** - Message queue-based integration
- **[1.3.2 Kafka Integration](./docker/kafka/README.md)** ✅ **Ready** - Event streaming integration

### 2. Helm Chart Integration

#### 2.0 Sandbox Environments
- **[2.0.1 Monolithic API Sandbox](./sandbox/helm/api/monolithic/README.md)** ✅ **Ready** - Complete Kubernetes sandbox with monolithic architecture (REST API)
- **[2.0.2 Microservice API Sandbox](./sandbox/helm/api/microservice/README.md)** ✅ **Ready** - Complete Kubernetes sandbox with microservice architecture (REST API)
- **[2.0.3 RabbitMQ Sandbox](./sandbox/helm/rabbitmq/README.md)** ✅ **Ready** - Complete Kubernetes sandbox with RabbitMQ message queue integration
- **[2.0.4 Kafka Sandbox](./sandbox/helm/kafka/README.md)** ✅ **Ready** - Complete Kubernetes sandbox with Apache Kafka event streaming integration

#### 2.1 Monolithic Architecture
- **[2.1.1 API Integration](./helm/api/monolithic/README.md)** ✅ **Ready** - Kubernetes deployment with Helm charts

#### 2.2 Microservice Architecture
- **[2.2.1 API Integration](./helm/api/microservice/README.md)** ✅ **Ready** - Kubernetes deployment with Helm charts

#### 2.3 Message Queue & Event Streaming (Works for both architectures)
- **[2.3.1 RabbitMQ Integration](./helm/rabbitmq/README.md)** ✅ **Ready** - Kubernetes deployment with RabbitMQ
- **[2.3.2 Kafka Integration](./helm/kafka/README.md)** ✅ **Ready** - Kubernetes deployment with Kafka

---

## Configuration

### Repository Structure

```
ev_charging_sandbox/
├── docker/
│   ├── api/
│   │   ├── monolithic/               # ✅ Standalone ONIX adapter integration
│   │   │   ├── docker-compose-onix-bap-plugin.yml
│   │   │   ├── docker-compose-onix-bpp-plugin.yml
│   │   │   ├── config/
│   │   │   │   ├── onix-bap/
│   │   │   │   │   ├── adapter.yaml
│   │   │   │   │   ├── bap_caller_routing.yaml
│   │   │   │   │   └── bap_receiver_routing.yaml
│   │   │   │   └── onix-bpp/
│   │   │   │       ├── adapter.yaml
│   │   │   │       ├── bpp_caller_routing.yaml
│   │   │   │       └── bpp_receiver_routing.yaml
│   │   │   └── README.md
│   │   └── microservice/             # ✅ Microservice API integration
│   │       ├── docker-compose-onix-bap-plugin.yml
│   │       ├── docker-compose-onix-bpp-plugin.yml
│   │       ├── config/
│   │       │   ├── onix-bap/
│   │       │   │   ├── adapter.yaml
│   │       │   │   ├── bap_caller_routing.yaml
│   │       │   │   └── bap_receiver_routing.yaml
│   │       │   └── onix-bpp/
│   │       │       ├── adapter.yaml
│   │       │       ├── bpp_caller_routing.yaml
│   │       │       └── bpp_receiver_routing.yaml
│   │       └── README.md
│   ├── kafka/                        # Kafka integration
│   │   ├── config/
│   │   │   ├── onix-bap/
│   │   │   │   ├── adapter.yaml
│   │   │   │   ├── bapTxnCaller-routing.yaml
│   │   │   │   └── bapTxnReciever-routing.yaml
│   │   │   └── onix-bpp/
│   │   │       ├── adapter.yaml
│   │   │       ├── bppTxnCaller-routing.yaml
│   │   │       └── bppTxnReciever-routing.yaml
│   │   ├── docker-compose-onix-bap-kafka-plugin.yml
│   │   ├── docker-compose-onix-bpp-kafka-plugin.yml
│   │   └── README.md
│   └── rabbitmq/                     # RabbitMQ integration
│       ├── config/
│       │   ├── onix-bap/
│       │   │   ├── adapter.yaml
│       │   │   ├── bapTxnCaller-routing.yaml
│       │   │   ├── bapTxnReciever-routing.yaml
│       │   │   └── plugin.yaml
│       │   └── onix-bpp/
│       │       ├── adapter.yaml
│       │       ├── bppTxnCaller-routing.yaml
│       │       ├── bppTxnReciever-routing.yaml
│       │       └── plugin.yaml
│       ├── docker-compose-onix-bap-rabbit-mq-plugin.yml
│       ├── docker-compose-onix-bpp-rabbit-mq-plugin.yml
│       └── README.md
├── sandbox/                          # ✅ Complete sandbox environments
│   ├── docker/                       # Docker Compose sandbox environments
│   │   ├── api/
│   │   │   ├── monolithic/           # Monolithic API sandbox with all services
│   │   │   │   ├── docker-compose.yml
│   │   │   │   ├── onix-bap_config.yml
│   │   │   │   ├── onix-bpp_config.yml
│   │   │   │   ├── mock-registry_config.yml
│   │   │   │   ├── mock-cds_config.yml
│   │   │   │   ├── mock-bap_config.yml
│   │   │   │   ├── mock-bpp_config.yml
│   │   │   │   └── README.md
│   │   │   └── microservice/          # Microservice API sandbox with all services
│   │   │       ├── docker-compose.yml
│   │   │       ├── onix-bap_config.yml
│   │   │       ├── onix-bpp_config.yml
│   │   │       ├── mock-registry_config.yml
│   │   │       ├── mock-cds_config.yml
│   │   │       ├── mock-bap_config.yml
│   │   │       ├── mock-bpp_config.yml
│   │   │       └── README.md
│   │   ├── kafka/                    # Kafka sandbox
│   │   │   ├── docker-compose.yml
│   │   │   ├── mock-bap-kafka_config.yml
│   │   │   ├── mock-bpp-kafka_config.yml
│   │   │   ├── mock-cds_config.yml
│   │   │   ├── mock-registry_config.yml
│   │   │   ├── message/              # Test messages and publishing scripts
│   │   │   │   ├── bap/
│   │   │   │   │   ├── example/      # JSON message files
│   │   │   │   │   ├── test/         # Publishing scripts
│   │   │   │   │   └── README.md
│   │   │   │   └── bpp/
│   │   │   │       ├── example/      # JSON callback files
│   │   │   │       ├── test/         # Publishing scripts
│   │   │   │       └── README.md
│   │   │   └── README.md
│   │   └── rabbitmq/                 # RabbitMQ sandbox
│   │       ├── docker-compose.yml
│   │       ├── mock-bap-rabbitMq_config.yml
│   │       ├── mock-bpp-rabbitMq_config.yml
│   │       ├── mock-cds_config.yml
│   │       ├── mock-registry_config.yml
│   │       ├── message/              # Test messages and publishing scripts
│   │       │   ├── bap/
│   │       │   │   ├── example/      # JSON message files
│   │       │   │   ├── test/        # Publishing scripts
│   │       │   │   └── README.md
│   │       │   └── bpp/
│   │       │       ├── example/      # JSON callback files
│   │       │       ├── test/        # Publishing scripts
│   │       │       └── README.md
│   │       └── README.md
│   ├── helm/                         # Helm/Kubernetes sandbox environments
│   │   ├── api/
│   │   │   ├── monolithic/           # Monolithic API Helm sandbox
│   │   │   │   ├── values-sandbox.yaml
│   │   │   │   └── README.md
│   │   │   └── microservice/          # Microservice API Helm sandbox
│   │   │       ├── values-sandbox.yaml
│   │   │       └── README.md
│   │   ├── kafka/                    # Kafka Helm sandbox
│   │   │   ├── values-sandbox.yaml
│   │   │   ├── mock-*.yml            # Mock service configs
│   │   │   ├── message/               # Test messages and publishing scripts
│   │   │   │   ├── bap/
│   │   │   │   │   ├── example/      # JSON message files
│   │   │   │   │   ├── test/         # Publishing scripts
│   │   │   │   │   └── README.md
│   │   │   │   └── bpp/
│   │   │   │       ├── example/      # JSON callback files
│   │   │   │       ├── test/         # Publishing scripts
│   │   │   │       └── README.md
│   │   │   └── README.md
│   │   └── rabbitmq/                 # RabbitMQ Helm sandbox
│   │       ├── values-sandbox.yaml
│   │       ├── mock-*.yml            # Mock service configs
│   │       ├── message/               # Test messages and publishing scripts
│   │       │   ├── bap/
│   │       │   │   ├── example/      # JSON message files
│   │       │   │   ├── test/        # Publishing scripts
│   │       │   │   └── README.md
│   │       │   └── bpp/
│   │       │       ├── example/      # JSON callback files
│   │       │       ├── test/        # Publishing scripts
│   │       │       └── README.md
│   │       └── README.md
│   ├── mock-bap/                     # Standalone mock BAP service (REST API)
│   ├── mock-bap-kafka/               # Standalone mock BAP service (Kafka)
│   ├── mock-bap-rabbitMq/            # Standalone mock BAP service (RabbitMQ)
│   ├── mock-bpp/                     # Standalone mock BPP service (REST API)
│   ├── mock-bpp-kafka/               # Standalone mock BPP service (Kafka)
│   ├── mock-bpp-rabbitMq/            # Standalone mock BPP service (RabbitMQ)
│   ├── mock-cds/                     # Standalone mock CDS service
│   └── mock-registry/                # Standalone mock Registry service
├── helm/
│   ├── api/
│   │   ├── monolithic/               # Helm chart for monolithic API
│   │   └── microservice/             # Helm chart for microservice API
│   ├── kafka/                        # Helm chart for Kafka
│   └── rabbitmq/                     # Helm chart for RabbitMQ
├── api-collection/                   # Postman collections and Swagger specs
├── schemas/                          # JSON schema files for validation
├── LICENSE
└── README.md                         # This file
```

### Configuration Files

Each integration method includes:

1. **Docker Compose Files**: Service definitions with networking and volumes
2. **Adapter Configuration** (`adapter.yaml`): Core adapter settings, modules, and plugins
   - For Kafka integrations, consumer plugin uses `consumer:` with `id: consumer` structure
   - For RabbitMQ integrations, consumer plugin uses `rabbitmqConsumer:` with `id: rabbitmqconsumer` structure
3. **Routing Configuration**: YAML files defining routing rules for BAP and BPP
4. **Environment Variables**: Container environment configuration

### Key Configuration Areas

- **HTTP Settings**: Port, timeouts, and connection pooling
- **Plugin Configuration**: Cache, router, signer, validators, consumer, publisher
- **Module Definition**: Transaction receivers and callers
- **Routing Rules**: Phase 1 (CDS) and Phase 2+ (Direct BPP) routing
- **Consumer Configuration**: For Kafka/RabbitMQ integrations, consumer plugin with `id: consumer` and configurable message consumption settings

---

## Usage Examples

### Complete Sandbox Environment

**Monolithic API Sandbox:**
```bash
# Navigate to the monolithic API sandbox directory
cd sandbox/docker/api/monolithic

# Start all services (ONIX adapters, mock services, Redis)
docker-compose up -d

# Check service status
docker-compose ps

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f onix-bap-plugin

# Stop all services
docker-compose down
```

**RabbitMQ Sandbox:**
```bash
# Navigate to the RabbitMQ sandbox directory
cd sandbox/docker/rabbitmq

# Start all services (ONIX adapters, RabbitMQ, mock services, Redis)
docker-compose up -d

# Check service status
docker-compose ps

# View logs for all services
docker-compose logs -f

# Publish test messages
cd message/bap/test && ./publish-all.sh

# Stop all services
docker-compose down
```

**Kafka Sandbox:**
```bash
# Navigate to the Kafka sandbox directory
cd sandbox/docker/kafka

# Start all services (ONIX adapters, Kafka, Zookeeper, mock services, Redis)
docker-compose up -d

# Check service status
docker-compose ps

# View logs for all services
docker-compose logs -f

# Publish test messages
cd message/bap/test && ./publish-all.sh

# Stop all services
docker-compose down
```

**Microservice API Sandbox:**
```bash
# Navigate to the microservice API sandbox directory
cd sandbox/docker/api/microservice

# Start all services (ONIX adapters, multiple mock services, Redis)
docker-compose up -d

# Check service status
docker-compose ps

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f onix-bap-plugin

# Stop all services
docker-compose down
```

**Helm Sandbox Environments:**

**Monolithic API Helm Sandbox:**
```bash
# Navigate to the monolithic API Helm sandbox directory
cd sandbox/helm/api/monolithic

# Deploy BAP component
helm install ev-charging-bap ../../../helm/api/monolithic \
  -f ../../../helm/api/monolithic/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy BPP component
helm install ev-charging-bpp ../../../helm/api/monolithic \
  -f ../../../helm/api/monolithic/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Check deployment status
kubectl get pods
kubectl get svc

# Port forward to access services locally
kubectl port-forward svc/onix-bap-plugin 8001:8001
kubectl port-forward svc/onix-bpp-plugin 8002:8002

# Uninstall
helm uninstall ev-charging-bap ev-charging-bpp
```

**Microservice API Helm Sandbox:**
```bash
# Navigate to the microservice API Helm sandbox directory
cd sandbox/helm/api/microservice

# Deploy BAP component
helm install ev-charging-bap ../../../helm/api/microservice \
  -f ../../../helm/api/microservice/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap

# Deploy BPP component
helm install ev-charging-bpp ../../../helm/api/microservice \
  -f ../../../helm/api/microservice/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp

# Check deployment status
kubectl get pods
kubectl get svc

# Uninstall
helm uninstall ev-charging-bap ev-charging-bpp
```

**Kafka Helm Sandbox:**
```bash
# Navigate to the Kafka Helm sandbox directory
cd sandbox/helm/kafka

# Deploy BAP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bap ../../../helm/kafka \
  -f ../../../helm/kafka/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-kafka-bpp ../../../helm/kafka \
  -f ../../../helm/kafka/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Check deployment status
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox

# Port forward Kafka UI
kubectl port-forward svc/kafka-ui 8080:8080 -n ev-charging-sandbox

# Uninstall
helm uninstall ev-charging-kafka-bap ev-charging-kafka-bpp --namespace ev-charging-sandbox
```

**RabbitMQ Helm Sandbox:**
```bash
# Navigate to the RabbitMQ Helm sandbox directory
cd sandbox/helm/rabbitmq

# Deploy BAP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-rabbitmq-bap ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bap.yaml \
  -f values-sandbox.yaml \
  --set component=bap \
  --namespace ev-charging-sandbox \
  --create-namespace

# Deploy BPP component (idempotent - installs or upgrades)
helm upgrade --install ev-charging-rabbitmq-bpp ../../../helm/rabbitmq \
  -f ../../../helm/rabbitmq/values-bpp.yaml \
  -f values-sandbox.yaml \
  --set component=bpp \
  --namespace ev-charging-sandbox \
  --create-namespace

# Check deployment status
kubectl get pods -n ev-charging-sandbox
kubectl get svc -n ev-charging-sandbox

# Port forward RabbitMQ Management UI
kubectl port-forward svc/rabbitmq 15672:15672 -n ev-charging-sandbox

# Uninstall
helm uninstall ev-charging-rabbitmq-bap ev-charging-rabbitmq-bpp --namespace ev-charging-sandbox
```

**Available Endpoints (Monolithic API):**
- **ONIX BAP**: `http://localhost:8001/bap/caller/{action}` and `http://localhost:8001/bap/receiver/{action}`
- **ONIX BPP**: `http://localhost:8002/bpp/caller/{action}` and `http://localhost:8002/bpp/receiver/{action}`
- **Mock Registry**: `http://localhost:3030`
- **Mock CDS**: `http://localhost:8082`
- **Mock BAP**: `http://localhost:9001`
- **Mock BPP**: `http://localhost:9002`

**Available Endpoints (RabbitMQ):**
- **ONIX BAP**: `http://localhost:8001/bap/receiver/{action}`
- **ONIX BPP**: `http://localhost:8002/bpp/receiver/{action}`
- **RabbitMQ Management UI**: `http://localhost:15672` (guest/guest)
- **Mock Registry**: `http://localhost:3030`
- **Mock CDS**: `http://localhost:8082`

**Available Endpoints (Kafka):**
- **ONIX BAP**: `http://localhost:8001/bap/receiver/{action}`
- **ONIX BPP**: `http://localhost:8002/bpp/receiver/{action}`
- **Kafka**: `localhost:9092`
- **Mock Registry**: `http://localhost:3030`
- **Mock CDS**: `http://localhost:8082`

**Available Endpoints (Microservice API):**
- **ONIX BAP**: `http://localhost:8001/bap/caller/{action}` and `http://localhost:8001/bap/receiver/{action}`
- **ONIX BPP**: `http://localhost:8002/bpp/caller/{action}` and `http://localhost:8002/bpp/receiver/{action}`
- **Mock Registry**: `http://localhost:3030`
- **Mock CDS**: `http://localhost:8082`
- **Mock BAP Services**: `http://localhost:9001-9010` (one per endpoint)
- **Mock BPP Services**: `http://localhost:9011-9020` (one per endpoint)

**Available Endpoints (Helm Sandbox - after port forwarding):**
- **ONIX BAP**: `http://localhost:8001/bap/caller/{action}` and `http://localhost:8001/bap/receiver/{action}`
- **ONIX BPP**: `http://localhost:8002/bpp/caller/{action}` and `http://localhost:8002/bpp/receiver/{action}`
- **Mock Registry**: `http://localhost:3030` (after port forwarding)
- **Mock CDS**: `http://localhost:8082` (after port forwarding)
- **Kafka UI**: `http://localhost:8080` (Kafka sandbox only, after port forwarding)
- **RabbitMQ Management UI**: `http://localhost:15672` (RabbitMQ sandbox only, after port forwarding, guest/guest)

### Standalone ONIX Adapters

#### BAP Integration

```bash
# Navigate to the integration directory
cd docker/api/monolithic

# Start BAP services
docker-compose -f docker-compose-onix-bap-plugin.yml up -d

# Check service status
docker-compose -f docker-compose-onix-bap-plugin.yml ps

# View logs
docker-compose -f docker-compose-onix-bap-plugin.yml logs -f onix-bap-plugin

# Stop services
docker-compose -f docker-compose-onix-bap-plugin.yml down
```

**BAP Endpoints:**
- Caller: `http://localhost:8001/bap/caller/{action}`
- Receiver: `http://localhost:8001/bap/receiver/{action}`

#### BPP Integration

```bash
# Navigate to the integration directory
cd docker/api/monolithic

# Start BPP services
docker-compose -f docker-compose-onix-bpp-plugin.yml up -d

# Check service status
docker-compose -f docker-compose-onix-bpp-plugin.yml ps

# View logs
docker-compose -f docker-compose-onix-bpp-plugin.yml logs -f onix-bpp-plugin

# Stop services
docker-compose -f docker-compose-onix-bpp-plugin.yml down
```

**BPP Endpoints:**
- Caller: `http://localhost:8002/bpp/caller/{action}`
- Receiver: `http://localhost:8002/bpp/receiver/{action}`

### Example API Request

This example works with both the **Complete Sandbox** and **Standalone ONIX Adapters** setups:

```bash
# Send a discover request from BAP
# This will be routed to CDS (in sandbox) or your configured CDS endpoint
curl -X POST http://localhost:8001/bap/caller/discover \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "domain": "ev_charging_network",
      "version": "1.0.0",
      "action": "discover",
      "bap_id": "example-bap.com",
      "bap_uri": "http://mock-bap:9001",
      "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
      "message_id": "550e8400-e29b-41d4-a716-446655440001",
      "timestamp": "2023-06-15T09:30:00.000Z",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "fulfillment": {
          "start": {
            "location": {
              "gps": "12.9715987,77.5945627"
            }
          },
          "end": {
            "location": {
              "gps": "12.9715987,77.5945627"
            }
          }
        }
      }
    }
  }'
```

**Note**: 
- In the **Complete Sandbox** environment, `bap_uri` can reference `mock-bap:9001` for internal Docker network communication
- For **Standalone ONIX Adapters**, update `bap_uri` to point to your actual BAP backend service endpoint
- The request will be automatically routed to CDS (for discover) or BPP (for other actions) based on the routing configuration

---

## Documentation

### Integration Guides

#### Sandbox Environments

**Docker Sandbox Environments:**
- **[Monolithic API Sandbox Guide](./sandbox/docker/api/monolithic/README.md)**: ✅ Complete Docker sandbox with monolithic architecture (REST API)
- **[Microservice API Sandbox Guide](./sandbox/docker/api/microservice/README.md)**: ✅ Complete Docker sandbox with microservice architecture (REST API)
- **[RabbitMQ Sandbox Guide](./sandbox/docker/rabbitmq/README.md)**: ✅ Complete Docker sandbox with RabbitMQ message queue integration
- **[Kafka Sandbox Guide](./sandbox/docker/kafka/README.md)**: ✅ Complete Docker sandbox with Apache Kafka event streaming integration

**Helm/Kubernetes Sandbox Environments:**
- **[Monolithic API Helm Sandbox Guide](./sandbox/helm/api/monolithic/README.md)**: ✅ Complete Kubernetes sandbox with monolithic architecture (REST API)
- **[Microservice API Helm Sandbox Guide](./sandbox/helm/api/microservice/README.md)**: ✅ Complete Kubernetes sandbox with microservice architecture (REST API)
- **[RabbitMQ Helm Sandbox Guide](./sandbox/helm/rabbitmq/README.md)**: ✅ Complete Kubernetes sandbox with RabbitMQ message queue integration
- **[Kafka Helm Sandbox Guide](./sandbox/helm/kafka/README.md)**: ✅ Complete Kubernetes sandbox with Apache Kafka event streaming integration

**Standalone Mock Services:**
- **[Standalone Mock Services](./sandbox/)**: Individual mock service deployments (BAP/BPP for REST API, Kafka, and RabbitMQ; CDS, Registry)

#### ONIX Adapter Integration

**Docker Integration:**
- **[Monolithic API Integration](./docker/api/monolithic/README.md)**: ✅ Complete guide for standalone Docker-based ONIX adapter deployment
- **[Microservice API Integration](./docker/api/microservice/README.md)**: ✅ Complete guide for microservice architecture with endpoint-based routing
- **[RabbitMQ Integration](./docker/rabbitmq/README.md)**: ✅ Complete guide for RabbitMQ message queue-based integration (works for both monolithic and microservice architectures)
- **[Kafka Integration](./docker/kafka/README.md)**: ✅ Complete guide for Apache Kafka event streaming integration (works for both monolithic and microservice architectures)

**Helm Chart Integration:**
- **[Monolithic API Integration](./helm/api/monolithic/README.md)**: ✅ Complete guide for Kubernetes deployment with Helm charts
- **[Microservice API Integration](./helm/api/microservice/README.md)**: ✅ Complete guide for microservice Kubernetes deployment
- **[RabbitMQ Integration](./helm/rabbitmq/README.md)**: ✅ Complete guide for RabbitMQ Kubernetes deployment
- **[Kafka Integration](./helm/kafka/README.md)**: ✅ Complete guide for Kafka Kubernetes deployment

### Related Documentation

- **[ONIX-Adapter Repository](https://github.com/Beckn-One/beckn-onix)**: Official onix-adapter source code and documentation
- **[ONIX Configuration Guide](https://github.com/Beckn-One/beckn-onix/blob/main/CONFIG.md)**: Detailed configuration parameters
- **[ONIX Setup Guide](https://github.com/Beckn-One/beckn-onix/blob/main/SETUP.md)**: Installation and setup instructions
- **[Beckn Protocol Specifications](https://github.com/beckn/protocol-specifications)**: Protocol documentation

---

## Contributing

We welcome contributions! When contributing examples or improvements:

1. **Follow the directory structure**: Maintain consistency with existing examples
2. **Include documentation**: Each integration method should have a comprehensive README
3. **Provide working examples**: Include Docker Compose files, configuration files, and usage examples
4. **Add troubleshooting guides**: Help users resolve common issues
5. **Test your changes**: Ensure all configurations work before submitting

### Contribution Guidelines

- Clear documentation with inline comments
- Working configuration files
- Environment variable examples
- Troubleshooting sections
- Consistent code formatting

---

## Support

For issues, questions, or contributions:

1. **Check Documentation**: Review the relevant integration guide and troubleshooting sections
2. **Review Examples**: Examine existing configuration files and examples
3. **Open an Issue**: Report bugs or request features via GitHub Issues
4. **Check ONIX Repository**: Refer to the [main onix-adapter repository](https://github.com/Beckn-One/beckn-onix) for core functionality

### Resources

- **Issues**: [GitHub Issues](https://github.com/manendrapalsingh/ev_charging_sandbox/issues)
- **ONIX Issues**: [Beckn-One/beckn-onix Issues](https://github.com/Beckn-One/beckn-onix/issues)
- **ONIX Discussions**: [GitHub Discussions](https://github.com/Beckn-One/beckn-onix/discussions)

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

The onix-adapter itself is licensed under the MIT License. See the [onix-adapter LICENSE](https://github.com/Beckn-One/beckn-onix/blob/main/LICENSE) for more information.

---

## Acknowledgments

- **[Beckn Foundation](https://beckn.org)**: For the Beckn Protocol specifications
- **[Beckn-One](https://github.com/Beckn-One)**: For the onix-adapter project
- All contributors to the onix-adapter and this integration guide

---

Built with ❤️ for the open Value Network ecosystem
