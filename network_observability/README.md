# Network observability stack

Single compose: **Redis**, **Mock Registry**, **Onix BAP Plugin**, **OTEL Collector**, **Prometheus**, **Jaeger**, **Grafana**. The adapter sends OTLP to the collector; **Grafana** provides metrics dashboards (Prometheus); **Jaeger** provides trace search and timeline (UI at http://localhost:16686).

## Prerequisites

- Adapter config (`config/onix/adapter.yaml`) has `plugins.otelsetup` with `otlpEndpoint: "otel-collector:4317"`.
- If your adapter cache uses `addr: redis-bap:6379`, it will resolve via the `redis-bap` alias to `redis-onix-bap`. For Redis auth, configure the cache plugin or set `REDIS_PASSWORD` as needed.

## Quick start

From repo root:

```bash
CONFIG_PATH=./config SCHEMA_PATH=./schemas docker compose -f network_observability/docker-compose.yml up -d
```

- **BAP HTTP**: http://localhost:8001  
- **Grafana**: http://localhost:3000 — login `admin` / `admin`. Datasources: **Prometheus** (metrics), **Jaeger** (traces).  
- **Jaeger** (traces): http://localhost:16686 — trace search and timeline (service: **onix-ev-charging-bap**).  
- **Prometheus**: http://localhost:9090 — metrics.

## Grafana dashboards

Two dashboards are provisioned under the **Onix** folder:

- **Onix Metrics** — Prometheus-based: step execution, plugin execution, handler validations/routing, cache operations, and errors.  
- **Onix Traces** — Jaeger-based: Trace by ID in dashboard, or use **Jaeger UI** at http://localhost:16686 (service **onix-ev-charging-bap**) to search traces.

## Stack

| Service           | Role                                                | Ports |
|------------------|-----------------------------------------------------|--------|
| redis-onix-bap   | Redis (password: your-redis-password)               | 6379   |
| mock-registry    | Mock registry for adapter                           | 3030   |
| onix-bap-plugin  | BAP adapter (sends OTLP to collector)                | 8001, 9003 |
| otel-collector   | Receives OTLP; exports to Prometheus, Jaeger, and optionally Receiver API | 4317, 4318, 8889 |
| Prometheus       | Scrapes collector metrics                           | 9090   |
| Jaeger           | Trace storage + UI (receives OTLP)                  | 16686 |
| Grafana          | Dashboards (metrics + traces)                       | 3000   |

## Forwarding to Network Operator Receiver API

The OTEL Collector can forward telemetry (metrics, traces, and logs) to the Beckn Network Operator's Receiver API (e.g. `POST /v1/telemetry` or standard OTLP HTTP endpoints).

- Set **`RECEIVER_OTLP_ENDPOINT`** to the Receiver's base URL when running the stack (e.g. in docker-compose or in your shell before `docker compose up`). Example: `https://receiver.network-operator.example` or `https://receiver.example.com/v1`. The collector sends OTLP over HTTP with gzip compression to the standard paths `/v1/traces`, `/v1/metrics`, and `/v1/logs`.
- If unset, the default is `http://127.0.0.1:4318` so the collector starts; export attempts to the Receiver will not reach an external service.
- For Receiver APIs that require authentication or TLS, configure the `otlphttp/receiver` exporter in `otel-collector/config.yaml` (e.g. `headers`, `tls` under `otlphttp/receiver`).

Example with forwarding enabled:

```bash
RECEIVER_OTLP_ENDPOINT=https://receiver.example.com docker compose -f network_observability/docker-compose.yml up -d
```

## Environment

- `CONFIG_PATH` — path to config dir (default `../../config`); adapter uses `$CONFIG_PATH/onix` (same as `config/onix/adapter.yaml`).
- `SCHEMA_PATH` — path to schemas dir (default `../../schemas`).
- `REDIS_PASSWORD` — set in onix-bap-plugin; use same value as Redis `--requirepass` (default `your-redis-password`).
- `RECEIVER_OTLP_ENDPOINT` — optional; base URL of the Network Operator Receiver API for forwarding telemetry (see above).

## Files

- `otel-collector/config.yaml` — OTLP receiver, batch processor, Prometheus + Jaeger exporters, optional otlphttp/receiver (forward to Network Operator; set `RECEIVER_OTLP_ENDPOINT`).
- `prometheus/prometheus.yml` — Scrapes `otel-collector:8889`.
- `grafana/provisioning/datasources/datasources.yml` — Prometheus and Jaeger datasources.
- `grafana/provisioning/dashboards/` — Dashboard provider and JSON dashboards (Onix Metrics, Onix Traces).
- `docker-compose.yml` — Redis, mock-registry, onix-bap-plugin, otel-collector, Prometheus, Jaeger, Grafana.
