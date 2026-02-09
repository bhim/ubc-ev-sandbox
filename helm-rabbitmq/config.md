# Configuration Reference - Helm RabbitMQ Adapter

This Helm chart deploys the ONIX RabbitMQ adapter for Kubernetes. The adapter configuration is templated from `values.yaml` with dynamic service name replacement and component-specific transformations, then injected via Kubernetes ConfigMaps.

## Configuration Source

The adapter configuration is based on the RabbitMQ adapter configurations documented in:
- **[onix-adaptor-rabbitMQ/config.md](../onix-adaptor-rabbitMQ/config.md)** - Complete RabbitMQ adapter configuration reference

## Configuration Files

- **Values File**: `values.yaml` (base configuration)
- **BAP Values**: `values-bap.yaml` (BAP-specific overrides)
- **BPP Values**: `values-bpp.yaml` (BPP-specific overrides)
- **ConfigMap Template**: `templates/configmap.yaml` (generates Kubernetes ConfigMaps with dynamic replacements)

## How Configuration Works

1. **Adapter Configuration**: Defined in `values.yaml` under `config.adapter` (base template, typically BAP)
2. **Routing Configuration**: Defined in `values.yaml` under `config.routing.caller` and `config.routing.receiver`
3. **Dynamic Service Replacement**: Helm template automatically replaces:
   - RabbitMQ broker: `rabbitmq:5672` → `<fullname>-rabbitmq:<port>`
   - Redis address: `redis-bap:6379` → `<fullname>-redis-<component>:<port>`
   - Registry URL: `http://mock-registry:3030` → Configurable via `config.registryUrl`
4. **Component-Specific Transformations**: For BPP, template performs string replacements to convert BAP config to BPP config
5. **ConfigMap Generation**: Helm template generates ConfigMaps with:
   - Routing YAML files
   - `adapter.yaml` with replaced service names
   - `plugin.yaml` for RabbitMQ plugin configuration

## Helm-Specific Overrides

The Helm chart applies the following service name replacements automatically:

### Service Name Replacements

| Original Value | Helm Replacement | Description |
|----------------|------------------|-------------|
| `rabbitmq:5672` | `<fullname>-rabbitmq:<port>` | RabbitMQ broker address based on Helm release name |
| `redis-bap:6379` | `<fullname>-redis-<component>:<port>` | Redis address for BAP component |
| `redis-bpp:6379` | `<fullname>-redis-<component>:<port>` | Redis address for BPP component |
| `http://mock-registry:3030` | Configurable via `config.registryUrl` | Registry URL override |
| `username: guest` | `username: admin` | RabbitMQ username (overridden) |
| `password: guest` | `password: admin` | RabbitMQ password (overridden) |

### Component-Specific Replacements (BPP)

When `component=bpp`, the template performs additional replacements:

| Original (BAP) | Replacement (BPP) | Description |
|----------------|-------------------|-------------|
| `bapTxnReceiver` | `bppTxnReceiver` | Module name |
| `bapTxnCaller` | `bppTxnCaller` | Module name |
| `role: bap` | `role: bpp` | Handler role |
| `subscriberId: ev-charging.sandbox1.com` | `subscriberId: ev-charging.sandbox2.com` | Subscriber ID |
| `networkParticipant: ev-charging.sandbox1.com` | `networkParticipant: ev-charging.sandbox2.com` | Network participant |
| `port: 8001` | `port: 8002` | HTTP port |
| `consumer.queueName: "bap_caller_queue"` | `consumer.queueName: "bpp_caller_queue"` | Queue name |
| `consumer.routingKeys: "bap.*"` | `consumer.routingKeys: "bpp.on_*"` | Routing keys |
| `routingConfig: /app/config/bapTxn*` | `routingConfig: /app/config/bppTxn*` | Routing config paths |
| `path: /bap/receiver/` | `path: /bpp/receiver/` | HTTP path |
| `appName: "onix-ev-charging"` | `appName: "bpp-ev-charging"` | Application name |
| `metricsPort: "9003"` | `metricsPort: "9004"` | Metrics port |
| `keyId: bap-key-1` | `keyId: bpp-key-1` | Key ID |
| BAP signing keys | BPP signing keys | Key replacement |

### Dynamic Replacement Logic

The ConfigMap template performs the following replacements:

```yaml
{{- $fullname := include "onix-rabbitmq.fullname" . }}
{{- $redisHost := printf "%s-redis-%s" $fullname .Values.component }}
{{- $redisPort := int (.Values.redis.service.port | default 6379) }}
{{- $redisAddr := printf "%s:%d" $redisHost $redisPort }}
{{- $rabbitmqBroker := .Values.rabbitmq.broker }}
{{- if not $rabbitmqBroker }}
{{- if .Values.rabbitmq.enabled }}
{{- $rabbitmqPort := int (.Values.rabbitmq.service.amqpPort | default 5672) }}
{{- $rabbitmqBroker = printf "%s-rabbitmq:%d" $fullname $rabbitmqPort }}
{{- end }}
{{- end }}
{{- $adapterConfig = $adapterConfig | replace "redis-bpp:6379" $redisAddr }}
{{- $adapterConfig = $adapterConfig | replace "redis-bap:6379" $redisAddr }}
{{- $adapterConfig = $adapterConfig | replace "rabbitmq:5672" $rabbitmqBroker }}
{{- $adapterConfig = $adapterConfig | replace "username: guest" "username: admin" }}
{{- $adapterConfig = $adapterConfig | replace "password: guest" "password: admin" }}
{{- if eq .Values.component "bpp" }}
  # BPP-specific replacements (see table above)
{{- end }}
```

### ConfigMap Structure

**ConfigMap: Adapter and Routing Configuration**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "onix-rabbitmq.fullname" . }}-{{ .Values.component }}-config
data:
  adapter.yaml: |
    {{ $adapterConfig | indent 4 }}  # With service name and component replacements
  bapTxnCaller-routing.yaml: |  # or bppTxnCaller-routing.yaml
    {{ .Values.config.routing.caller | indent 4 }}
  bapTxnReciever-routing.yaml: |  # or bppTxnReciever-routing.yaml
    {{ .Values.config.routing.receiver | indent 4 }}
  plugin.yaml: |
    {{ .Values.config.plugin | indent 4 }}
```

## Configuration Values

### Base Configuration (`values.yaml`)

| Key | Description |
|-----|-------------|
| `component` | Component type: `bap` or `bpp` |
| `fullnameOverride` | Override for service naming |
| `image.repository` | Docker image repository |
| `image.tag` | Docker image tag |
| `service.port` | Kubernetes service port (8001 for BAP, 8002 for BPP) |
| `rabbitmq.enabled` | Enable RabbitMQ deployment |
| `rabbitmq.broker` | RabbitMQ broker address (empty = auto-generate from fullname) |
| `rabbitmq.service.amqpPort` | RabbitMQ AMQP port (default: 5672) |
| `redis.enabled` | Enable Redis deployment |
| `redis.service.port` | Redis service port (default: 6379) |
| `config.adapter` | Complete adapter.yaml content (base template, typically BAP) |
| `config.routing.caller` | Caller routing YAML content |
| `config.routing.receiver` | Receiver routing YAML content |
| `config.routing.callerBpp` | BPP-specific caller routing (if different) |
| `config.routing.receiverBpp` | BPP-specific receiver routing (if different) |
| `config.plugin` | RabbitMQ plugin configuration |
| `config.registryUrl` | Registry service URL (default: `http://mock-registry:3030`) |
| `retry.registry.maxRetries` | Registry retry max attempts (default: 3) |
| `retry.registry.waitMin` | Registry retry min wait (default: "100ms") |
| `retry.registry.waitMax` | Registry retry max wait (default: "500ms") |

### BAP-Specific Configuration (`values-bap.yaml`)

| Key | Value | Description |
|-----|-------|-------------|
| `component` | `bap` | Component type |
| `service.port` | `8001` | BAP service port |
| `rabbitmq.enabled` | `true` | BAP release includes RabbitMQ |
| `config.adapter` | BAP RabbitMQ adapter.yaml content | See [onix-adaptor-rabbitMQ/config.md](../onix-adaptor-rabbitMQ/config.md) |

### BPP-Specific Configuration (`values-bpp.yaml`)

| Key | Value | Description |
|-----|-------|-------------|
| `component` | `bpp` | Component type |
| `service.port` | `8002` | BPP service port |
| `rabbitmq.enabled` | `false` | BPP uses shared RabbitMQ from BAP release |
| `rabbitmq.broker` | `""` | Auto-detect from BAP release |
| `config.adapter` | BAP adapter.yaml template (converted to BPP via replacements) | See [onix-adaptor-rabbitMQ/config.md](../onix-adaptor-rabbitMQ/config.md) |

## Service Names

When deployed, services are named based on the Helm release name:

| Service Type | Service Name Pattern | Example |
|-------------|---------------------|---------|
| **RabbitMQ** | `<release-name>-rabbitmq` | `onix-rabbitmq` |
| **BAP Service** | `<release-name>-bap-service` | `onix-bap-service` |
| **BPP Service** | `<release-name>-bpp-service` | `onix-bpp-service` |
| **Redis BAP** | `<release-name>-redis-bap` | `onix-redis-bap` |
| **Redis BPP** | `<release-name>-redis-bpp` | `onix-redis-bpp` |

## Deployment Example

```bash
# Deploy BAP (includes RabbitMQ)
helm install onix-bap ./helm-rabbitmq \
  -f ./helm-rabbitmq/values-bap.yaml

# Deploy BPP (uses shared RabbitMQ from BAP)
helm install onix-bpp ./helm-rabbitmq \
  -f ./helm-rabbitmq/values-bpp.yaml
```

## Configuration Override

To override configuration values:

```bash
# Override RabbitMQ broker address
helm install onix-bpp ./helm-rabbitmq \
  -f ./helm-rabbitmq/values-bpp.yaml \
  --set rabbitmq.broker=external-rabbitmq:5672

# Override registry URL
helm install onix-bap ./helm-rabbitmq \
  -f ./helm-rabbitmq/values-bap.yaml \
  --set config.registryUrl=http://custom-registry:3030

# Override retry configuration
helm install onix-bap ./helm-rabbitmq \
  -f ./helm-rabbitmq/values-bap.yaml \
  --set retry.registry.maxRetries=5
```

## RabbitMQ Exchange and Queue Configuration

### Exchange
- **Name**: `beckn_exchange`
- **Type**: Topic exchange
- **Durable**: `true`

### BAP Queues
- **Queue Name**: `bap_caller_queue`
- **Routing Keys**: `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
- **Durable**: `true`

### BPP Queues
- **Queue Name**: `bpp_caller_queue`
- **Routing Keys**: `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`, `bpp.catalog_publish`, `bpp.on_catalog_publish`
- **Durable**: `true`

**Note**: Exchange and queues must be pre-configured or created via setup scripts before adapter starts.

## Viewing Generated Configuration

After deployment, view the generated ConfigMaps:

```bash
# View adapter ConfigMap
kubectl get configmap onix-bap-config -o yaml

# View routing configuration
kubectl get configmap onix-bap-config -o jsonpath='{.data.bapTxnCaller-routing\.yaml}'

# Verify service name replacements
kubectl get configmap onix-bap-config -o jsonpath='{.data.adapter\.yaml}' | grep -E "(rabbitmq|redis)"

# Verify BPP component replacements
kubectl get configmap onix-bpp-config -o jsonpath='{.data.adapter\.yaml}' | grep -E "(bpp|8002)"
```

## Additional Resources

- **[onix-adaptor-rabbitMQ/config.md](../onix-adaptor-rabbitMQ/config.md)**: Complete RabbitMQ adapter configuration reference
- **[helm-rabbitmq/README.md](./README.md)**: Helm RabbitMQ deployment guide
- **[values.yaml](./values.yaml)**: Base Helm values file
- **[values-bap.yaml](./values-bap.yaml)**: BAP-specific values
- **[values-bpp.yaml](./values-bpp.yaml)**: BPP-specific values
