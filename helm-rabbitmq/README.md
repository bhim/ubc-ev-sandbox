# Helm Chart - ONIX Adaptor with RabbitMQ

Helm chart for deploying the ONIX BAP and BPP adapters with RabbitMQ, aligned with [onix-adaptor-rabbitMQ](../onix-adaptor-rabbitMQ/). Uses the unified `manendrapalsingh/onix-adapter` image (same as the Docker Compose setup). Each release deploys one component (BAP or BPP) with its own RabbitMQ and Redis, or BPP can use the BAP RabbitMQ instance.

## Overview

- **Image**: `manendrapalsingh/onix-adapter:v0.9.3` (single image for both BAP and BPP)
- **Config**: `CONFIG_FILE=/app/config/adapter.yaml`; config (adapter, routing, `plugin.yaml`) is mounted at `/app/config`
- **Schema validation**: `schemav2validator` with upstream URL (`https://raw.githubusercontent.com/beckn/protocol-specifications-v2/...`); no local schema files or schema ConfigMap

## Install

### BAP

```bash
helm install ev-charging-rabbitmq-bap helm-rabbitmq -f values-bap.yaml -n <namespace>
```

### BPP

```bash
helm install ev-charging-rabbitmq-bpp helm-rabbitmq -f values-bpp.yaml -n <namespace>
```

BPP by default uses the BAP RabbitMQ service (`rabbitmq.enabled: false`, `rabbitmq.broker`). Ensure the BAP release is installed first and the broker host matches your BAP release name.

### With an umbrella or script

Use `values-bap.yaml` and `values-bpp.yaml` with release names that match `rabbitmq.broker` and any cross-references (e.g. BAP↔BPP HTTP).

## Configuration

| Value | Default | Description |
|-------|---------|-------------|
| `config.registryUrl` | `http://mock-registry:3030` | Registry URL used in adapter and routing |
| `config.cdsUrl` | `http://mock-cds:8082` | CDS URL used in routing (caller) |
| `redis.password` | `""` | If set, Redis uses `--requirepass` and the adapter receives `REDIS_PASSWORD` |

Override in a values file or `--set`:

```bash
helm install ev-charging-rabbitmq-bap helm-rabbitmq -f values-bap.yaml \
  --set config.registryUrl=http://mock-registry.my-ns:3030 \
  --set config.cdsUrl=http://mock-cds.my-ns:8082 \
  --set redis.password=mysecret
```

## Config layout in the container

ConfigMap is mounted at `/app/config` with:

- `adapter.yaml` – main adapter config (BAP or BPP-specific via template substitutions)
- `bapTxnCaller-routing.yaml` / `bapTxnReciever-routing.yaml` (BAP) or `bppTxnCaller-routing.yaml` / `bppTxnReciever-routing.yaml` (BPP)
- `plugin.yaml` – plugin list (shared)

Substitutions (Redis, RabbitMQ, credentials, `config.registryUrl`, `config.cdsUrl`) and BPP-specific transforms are applied when rendering the ConfigMap.
