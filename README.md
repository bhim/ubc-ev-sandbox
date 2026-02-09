# UBC EV Charging Sandbox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://www.docker.com/)
[![ONIX Adapter](https://img.shields.io/badge/ONIX%20Adapter-v0.9.3-blue.svg)](https://github.com/Beckn-One/beckn-onix)

**A comprehensive sandbox environment for testing and developing EV Charging network integrations using the ONIX protocol adapter (Beckn-ONIX) with BAP and BPP applications**

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Overview

This repository provides a complete sandbox environment for integrating the **[onix-adapter](https://github.com/Beckn-One/beckn-onix)** (also known as Beckn-ONIX) with **BAP (Application Platform)** and **BPP (Provider Platform)** applications for EV Charging networks.

### What is Onix-Adapter?

The **onix-adapter** is a production-ready, plugin-based middleware adapter for the Beckn Protocol. It acts as a protocol adapter between Application Platforms (BAPs) and Provider Platforms (BPPs), ensuring secure, validated, and compliant message exchange across various commerce networks.

### Key Concepts

- **BAP (Application Platform)**: Buyer-side applications that help users search for and purchase products/services (e.g., consumer apps, aggregators)
- **BPP (Provider Platform)**: Seller-side platforms that provide products/services (e.g., merchant platforms, service providers)
- **Onix-Adapter**: Middleware that handles protocol compliance, message signing, validation, and routing between BAPs and BPPs
- **CDS (Catalog Discovery Service)**: Aggregates discover requests from BAPs and broadcasts to registered BPPs
- **Registry**: Maintains a registry of all network participants (BAPs, BPPs, CDS)

---

## Features

### Multiple Deployment Options

- **Docker Compose**: Local development with REST API, Kafka, or RabbitMQ
- **Helm Charts**: Kubernetes deployment for REST API, Kafka, or RabbitMQ
- **Complete Sandbox**: Full testing environment with ONIX adapters and mock services
- **Standalone Adapters**: Deploy only ONIX adapters for integration with your own services

### Communication Patterns

- **REST API**: Synchronous HTTP/REST messaging (default)
- **Kafka**: Asynchronous message-based communication with Kafka topics
- **RabbitMQ**: Asynchronous message-based communication with RabbitMQ queues

### Enterprise-Ready

- **Ed25519 Digital Signatures**: Cryptographically secure message signing and validation
- **JSON Schema Validation**: Protocol compliance using URL-based schema validation
- **Configurable Routing**: YAML-based routing rules with Phase 1 (CDS) and Phase 2+ (direct) support
- **Production Features**: Health checks, secret management, OpenTelemetry metrics, structured logging

---

## Quick Start

### Prerequisites

- **Docker**: Docker Engine 20.10+ and Docker Compose 2.0+ (for Docker deployments)
- **Kubernetes**: Kubernetes cluster v1.20+ and Helm 3.x (for Helm deployments)

### Deployment Options

#### Docker Compose (Local Development)

- **REST API**: See [Sandbox Guide](./sandbox/README.md) - Complete sandbox with REST API
- **Kafka**: See [Sandbox Kafka Guide](./sandbox-kafka/README.md) - Kafka-based messaging
- **RabbitMQ**: See [Sandbox RabbitMQ Guide](./sandbox-rabbitMQ/README.md) - RabbitMQ-based messaging
- **Standalone Adapters**: See [ONIX Adapter Guide](./onix-adaptor/README.md) - Deploy only adapters

#### Helm Charts (Kubernetes)

- **REST API**: See [Helm Chart Guide](./helm/README.md) - REST API deployment
- **Kafka**: See [Helm Kafka Guide](./helm-kafka/README.md) - Kafka integration with KRaft mode
- **RabbitMQ**: See [Helm RabbitMQ Guide](./helm-rabbitmq/README.md) - RabbitMQ integration
- **Complete Sandbox (Kafka)**: See [Helm Sandbox Kafka Guide](./helm-sandbox-kafka/README.md) - Full sandbox with Kafka

---

## Architecture

### Communication Patterns

The sandbox supports three communication patterns:

1. **REST API** (Synchronous HTTP): Direct HTTP calls between services
2. **Kafka** (Asynchronous): Message-based communication via Kafka topics
3. **RabbitMQ** (Asynchronous): Queue-based communication via RabbitMQ exchanges

### Core Components

- **ONIX Adapters**: Protocol adapters for BAP and BPP with transaction modules (`bapTxnCaller`, `bapTxnReceiver`, `bppTxnCaller`, `bppTxnReceiver`)
- **Mock Services**: Registry, CDS, BAP, and BPP simulators for testing
- **Supporting Infrastructure**: Redis for caching, Kafka/RabbitMQ for messaging (when applicable)

### Integration Flow

- **Phase 1 (Discovery)**: BAP → ONIX BAP → CDS → ONIX BPP → BPP (aggregated results)
- **Phase 2+ (Transactions)**: BAP → ONIX BAP → ONIX BPP → BPP (direct communication)

For detailed architecture diagrams and flow descriptions, see the individual deployment guides.


## Repository Structure

### Docker Compose Deployments

- **`sandbox/`**: Complete REST API sandbox with all services
- **`sandbox-kafka/`**: Complete Kafka-based sandbox
- **`sandbox-rabbitMQ/`**: Complete RabbitMQ-based sandbox
- **`onix-adaptor/`**: Standalone REST API adapters
- **`onix-adaptor-kafka/`**: Standalone Kafka adapters
- **`onix-adaptor-rabbitMQ/`**: Standalone RabbitMQ adapters

### Helm Charts (Kubernetes)

- **`helm/`**: REST API Helm chart
- **`helm-kafka/`**: Kafka Helm chart (KRaft mode)
- **`helm-rabbitmq/`**: RabbitMQ Helm chart
- **`helm-sandbox-kafka/`**: Complete Kafka sandbox Helm deployment
- **`helm-sendbox/`**: Alternative sandbox Helm deployment

### Additional Resources

- **`mock/`**: Mock service configurations and Helm charts
- **`api-collection/`**: Postman collections and Swagger specifications
- **`charts/`**: Additional Helm chart variants

## Documentation

### Docker Compose Guides

- **[Sandbox (REST API)](./sandbox/README.md)**: Complete Docker sandbox with REST API
- **[Sandbox Kafka](./sandbox-kafka/README.md)**: Kafka-based sandbox
- **[Sandbox RabbitMQ](./sandbox-rabbitMQ/README.md)**: RabbitMQ-based sandbox
- **[ONIX Adapter (REST API)](./onix-adaptor/README.md)**: Standalone REST API adapters
- **[ONIX Adapter Kafka](./onix-adaptor-kafka/README.md)**: Standalone Kafka adapters
- **[ONIX Adapter RabbitMQ](./onix-adaptor-rabbitMQ/README.md)**: Standalone RabbitMQ adapters

### Helm Chart Guides

- **[Helm Chart (REST API)](./helm/README.md)**: Kubernetes REST API deployment
- **[Helm Kafka](./helm-kafka/README.md)**: Kafka integration on Kubernetes
- **[Helm RabbitMQ](./helm-rabbitmq/README.md)**: RabbitMQ integration on Kubernetes
- **[Helm Sandbox Kafka](./helm-sandbox-kafka/README.md)**: Complete Kafka sandbox on Kubernetes

### API Documentation

- **[API Collection Guide](./api-collection/README.md)**: Postman collections and Swagger specifications

### External Resources

- **[ONIX-Adapter Repository](https://github.com/Beckn-One/beckn-onix)**: Official onix-adapter source code
- **[ONIX Configuration Guide](https://github.com/Beckn-One/beckn-onix/blob/main/CONFIG.md)**: Configuration parameters
- **[ONIX Setup Guide](https://github.com/Beckn-One/beckn-onix/blob/main/SETUP.md)**: Installation instructions
- **[Beckn Protocol Specifications](https://github.com/beckn/protocol-specifications)**: Protocol documentation

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

## Support

For issues, questions, or contributions:

1. **Check Documentation**: Review the relevant integration guide and troubleshooting sections
2. **Review Examples**: Examine existing configuration files and examples
3. **Open an Issue**: Report bugs or request features via GitHub Issues
4. **Check ONIX Repository**: Refer to the [main onix-adapter repository](https://github.com/Beckn-One/beckn-onix) for core functionality

### Resources

- **ONIX Issues**: [Beckn-One/beckn-onix Issues](https://github.com/Beckn-One/beckn-onix/issues)
- **UBC EV Sandbox Repo**: [bhim/ubc-ev-sandbox (Discussions & updates)](https://github.com/bhim/ubc-ev-sandbox)

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

The onix-adapter itself is licensed under the MIT License. See the [onix-adapter LICENSE](https://github.com/Beckn-One/beckn-onix/blob/main/LICENSE) for more information.

## Acknowledgments

- **[Beckn Foundation](https://beckn.org)**: For the Beckn Protocol specifications
- **[Beckn-One](https://github.com/Beckn-One)**: For the onix-adapter project
- All contributors to the onix-adapter and this integration guide

Built with ❤️ for the open Value Network ecosystem
