# OTEL Collector Setup For Network Participants

This guide explains how a network participant can run an OpenTelemetry collector on its own side together with an ONIX deployment.

It is written to be reusable outside this repository, but it also includes a working ONIX example block that can be copied directly.

## Goal

Run ONIX and a participant-side OTEL collector together so that:

- ONIX sends telemetry to a local OTEL collector over OTLP gRPC
- the collector exposes local metrics and health endpoints
- the collector can optionally forward selected telemetry upstream if your environment requires it

## Core Deployment Pattern

The simplest pattern is:

1. Run the ONIX application.
2. Run one OTEL collector close to that application.
3. Point ONIX to the collector on port `4317`.

For Docker, the endpoint is usually the collector service name, for example `participant-otel-collector:4317`.

For Kubernetes:

- if the collector is a sidecar in the same pod, use `localhost:4317`
- if the collector is a separate service, use `<collector-service-name>:4317`

## Working ONIX OTEL Plugin Block

This is the working `otelsetup` block currently used in ONIX and should be the base example in this guide:

```yaml
plugins:
  otelsetup:
    id: otelsetup
    config:
      serviceName: "onix"
      serviceVersion: "v0.9.5"
      environment: "production"
      domain: "UBC"
      otlpEndpoint: "otel-collector:4317"
      enableMetrics: "true"
      networkMetricsGranularity: "2min"
      networkMetricsFrequency: "4min"
      enableTracing: "true"
      enableLogs: "true"
      timeInterval: "5"
      auditFieldsConfig: "https://raw.githubusercontent.com/manendrapalsingh/ubc-ev-sandbox/refs/heads/feat/v0.9.5/audit-fields.yaml"
      cacheTTL: "3600"
```

What each important field does:

- `serviceName`: the service identity shown in telemetry backends
- `serviceVersion`: version tag attached to telemetry
- `environment`: environment label such as `development` or `production`
- `domain`: business domain label used by the ONIX plugin
- `otlpEndpoint`: the participant-side collector endpoint ONIX sends to
- `enableMetrics`, `enableTracing`, `enableLogs`: turn signals on
- `networkMetricsGranularity`, `networkMetricsFrequency`, `timeInterval`: timing controls for emitted telemetry
- `auditFieldsConfig`: external audit field definition used by the plugin
- `cacheTTL`: cache duration used by the plugin

For BPP, the structure stays the same. The main changes are typically:

- `serviceName`
- `otlpEndpoint`

## Docker Compose Wiring For ONIX

The ONIX container also needs OTLP environment wiring in Docker Compose.

Working example:

```yaml
environment:
  - OTEL_EXPORTER_OTLP_INSECURE=true
  - OTEL_EXPORTER_OTLP_ENDPOINT=otel-collector:4317
```

Use these values in your own Docker setup:

- `OTEL_EXPORTER_OTLP_INSECURE=true` when collector traffic is plain gRPC inside the Docker network
- `OTEL_EXPORTER_OTLP_ENDPOINT=<collector-service-name>:4317` so ONIX can reach the participant-side collector

A minimal Compose pattern looks like this:

```yaml
services:
  onix-app:
    environment:
      - OTEL_EXPORTER_OTLP_INSECURE=true
      - OTEL_EXPORTER_OTLP_ENDPOINT=participant-otel-collector:4317

  participant-otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel/config.yaml"]
    volumes:
      - ./otel-collector/config.yaml:/etc/otel/config.yaml:ro
```

The app and collector must be on the same Docker network.

## How To Read The Collector `config.yaml`

The working collector config has five important sections.

### 1. `receivers`

This is where the collector accepts telemetry from ONIX.

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
```

Meaning:

- OTLP over gRPC is enabled
- the collector listens on port `4317`
- ONIX should point its `otlpEndpoint` to this address

### 2. `processors`

Processors clean, batch, transform, or filter telemetry before export.

In the working config:

- `batch` and `batch/traces` improve export efficiency
- `filter/network_metrics` keeps only selected metrics for forwarding
- `transform/beckn_ids` maps Beckn transaction IDs into trace IDs
- `filter/network_traces` keeps only selected spans
- `filter/network_logs` keeps only selected audit logs

If you want a participant-only local setup, you can keep the batching processors and remove the forwarding-related filters and transforms that you do not need.

### 3. `exporters`

Exporters decide where telemetry goes after the collector receives it.

In the working ONIX config:

- `prometheus` exposes local metrics on `8889`
- `otlp_grpc/jaeger` sends traces to Jaeger for local debugging
- `otlp_http/collector2` forwards selected telemetry upstream

If your participant deployment is only for local observability, you can keep:

- `prometheus`
- `otlp_grpc/jaeger` if you run Jaeger

and remove or replace the upstream forwarder exporter.

### 4. `extensions`

Extensions add helper behavior around the collector.

In the working config:

- `oauth2client` gets client credentials when upstream forwarding needs auth
- `health_check` exposes the health endpoint on `13133`
- `zpages` enables debug pages on `55679`

If your deployment does not require authenticated upstream export, you can omit `oauth2client`.

### 5. `service`

The `service` section connects receivers, processors, exporters, and extensions into pipelines.

In the working config, the important pipeline idea is:

- one set of pipelines is used for local observability
- another set of pipelines is used for optional filtered forwarding

For a participant-side deployment, you can start with local pipelines first and add upstream forwarding later if required.

## Full Working Collector Config

If you want the exact working collector example, use the full config below.

```yaml
# OpenTelemetry Collector  - receives OTLP from onix-plugin
# Adapter sends to otel-collector:4317.
# App-level: all signals to Prometheus (metrics) and Jaeger (traces) for local debugging.
# Network-level: filtered signals to otel-collector-network.

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    send_batch_size: 1024
    timeout: 10s
  batch/traces:
    send_batch_size: 1024
    timeout: 2s

  # Network-level filter: only forward Beckn spec metrics to the receiver.
  # Drops internal app metrics (onix_step_*, onix_plugin_*, beckn_*, runtime.*).
  # OTTL: drop any metric whose name is NOT onix_http_request_count.
  filter/network_metrics:
    error_mode: ignore
    metrics:
      metric:
        - 'name != "onix_http_request_count"'

  # Map Beckn transaction_id -> trace_id and message_id -> span_id for UI correlation.
  # UUID format: remove hyphens for trace_id (32 hex chars); first 16 hex chars for span_id.
  transform/beckn_ids:
    error_mode: ignore
    trace_statements:
      - set(span.attributes["_beckn_tx"], span.attributes["transaction_id"]) where span.attributes["transaction_id"] != nil
      - replace_pattern(span.attributes["_beckn_tx"], "-", "") where span.attributes["_beckn_tx"] != nil
      - set(span.trace_id, TraceID(span.attributes["_beckn_tx"])) where span.attributes["_beckn_tx"] != nil

  # Network-level filter: only forward root API spans (have sender.id attribute).
  # Drops internal step:* child spans which don't have sender.id.
  # OTTL: drop any span where sender.id attribute is not present.
  filter/network_traces:
    error_mode: ignore
    traces:
      span:
        - 'attributes["sender.id"] == nil'

  # Network-level logs: only forward records that have checkSum attribute
  filter/network_logs:
    error_mode: ignore
    logs:
      log_record:
        - 'resource.attributes["eid"] != "AUDIT"'

exporters:
  # App-level: expose /metrics for Prometheus to scrape (Grafana displays)
  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: onix
    const_labels:
      observability: otel-collector
      service_name: onix-ev-charging

  # App-level: send traces to Jaeger (UI at http://localhost:16686)
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true

  # Network-level: forward to second collector (with OAuth2 Bearer token from Hydra)
  otlp_http/collector2:
    endpoint: https://obs.prod.ubc.nbsl.org.in
    auth:
      authenticator: oauth2client
    compression: gzip

extensions:
  oauth2client:
    token_url: https://obs-auth.prod.ubc.nbsl.org.in/oauth2/token
    client_id: ${env:OTEL_CLIENT_ID}
    client_secret: ${env:OTEL_CLIENT_SECRET}
    endpoint_params:
      audience: otel-collector-network
  health_check:
    endpoint: 0.0.0.0:13133
  zpages:
    endpoint: 0.0.0.0:55679

service:
  extensions: [oauth2client, health_check, zpages]
  pipelines:
    # App-level: ALL metrics -> Prometheus (stays local on the node)
    metrics/app:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]

    # Network-level: FILTERED metrics -> Collector 2
    metrics/network:
      receivers: [otlp]
      processors: [filter/network_metrics, batch]
      exporters: [otlp_http/collector2]

    # App-level: ALL traces -> transform Beckn IDs -> Jaeger (stays local on the node)
    traces/app:
      receivers: [otlp]
      processors: [ batch/traces]
      exporters: [otlp_grpc/jaeger]

    # Network-level: filter + transform Beckn IDs -> Collector 2
    traces/network:
      receivers: [otlp]
      processors: [filter/network_traces, transform/beckn_ids, batch/traces]
      exporters: [otlp_http/collector2]

    # Network-level: ALL audit logs -> Collector 2
    logs/network:
      receivers: [otlp]
      processors: [filter/network_logs, batch]
      exporters: [otlp_http/collector2]

  telemetry:
    logs:
      level: debug
```

## Docker Deployment At Participant Side

Use this when ONIX and the OTEL collector both run in Docker.

### Step 1. Update the ONIX adapter config

Use the working `otelsetup` block and set:

- `serviceName` to your participant service name
- `otlpEndpoint` to your collector service name on port `4317`

Example:

```yaml
otlpEndpoint: "participant-otel-collector:4317"
```

### Step 2. Update Docker Compose env vars

Make sure the ONIX container includes:

```yaml
environment:
  - OTEL_EXPORTER_OTLP_INSECURE=true
  - OTEL_EXPORTER_OTLP_ENDPOINT=participant-otel-collector:4317
```

### Step 3. Run the collector service

Mount your collector config and expose the local endpoints you care about:

```yaml
participant-otel-collector:
  image: otel/opentelemetry-collector-contrib:latest
  command: ["--config=/etc/otel/config.yaml"]
  volumes:
    - ./otel-collector/config.yaml:/etc/otel/config.yaml:ro
  ports:
    - "4317:4317"
    - "8889:8889"
    - "13133:13133"
```

### Step 4. Start both services together

Bring up ONIX and the collector in the same Compose project so service discovery works automatically.

## Kubernetes Deployment At Participant Side

For Kubernetes, the recommended pattern is a sidecar collector in the same pod as ONIX. That avoids separate service discovery for telemetry traffic.

### Sidecar pattern

Use `localhost:4317` from ONIX because both containers share the same pod network namespace.

Application config example:

```yaml
plugins:
  otelsetup:
    id: otelsetup
    config:
      serviceName: "participant-service"
      serviceVersion: "1.0.0"
      environment: "production"
      domain: "your_domain"
      otlpEndpoint: "localhost:4317"
      enableMetrics: "true"
      enableTracing: "true"
      enableLogs: "true"
```

Deployment pattern:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: onix-participant
spec:
  replicas: 1
  selector:
    matchLabels:
      app: onix-participant
  template:
    metadata:
      labels:
        app: onix-participant
    spec:
      containers:
        - name: onix
          image: your-onix-image:latest
          env:
            - name: OTEL_EXPORTER_OTLP_INSECURE
              value: "true"
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "localhost:4317"
        - name: otel-collector
          image: otel/opentelemetry-collector-contrib:latest
          args:
            - --config=/etc/otel/config.yaml
          ports:
            - containerPort: 4317
            - containerPort: 8889
            - containerPort: 13133
          volumeMounts:
            - name: otel-config
              mountPath: /etc/otel
      volumes:
        - name: otel-config
          configMap:
            name: onix-otel-config
```

Collector ConfigMap pattern:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: onix-otel-config
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
    exporters:
      prometheus:
        endpoint: "0.0.0.0:8889"
    extensions:
      health_check:
        endpoint: 0.0.0.0:13133
    service:
      extensions: [health_check]
      pipelines:
        metrics:
          receivers: [otlp]
          exporters: [prometheus]
```

### Separate collector service pattern

If you run the collector as a separate deployment, point ONIX to:

```yaml
otlpEndpoint: "participant-otel-collector:4317"
```

and create a Kubernetes `Service` for the collector.

## Local Verification

After deployment, verify these items first:

1. ONIX starts without OTEL configuration errors.
2. The collector starts without config parse errors.
3. The collector health endpoint responds.
4. The collector metrics endpoint responds.
5. Collector logs show incoming OTLP traffic.

Typical endpoints:

- health: `http://localhost:13133`
- metrics: `http://localhost:8889/metrics`

## Recommended Rollout Order

1. Enable the `otelsetup` block in ONIX.
2. Point ONIX to a local collector on `4317`.
3. Start with local collector metrics and health only.
4. Add local trace export if you need debugging.
5. Add upstream forwarding only after local collection is stable.

## Scope

This guide is for participant-side deployment only.

It explains:

- how to wire ONIX to a local OTEL collector
- how to understand the collector config structure
- how to deploy the setup in Docker or Kubernetes

It does not depend on a specific repository layout, even though the ONIX snippets shown here come from a working setup.
