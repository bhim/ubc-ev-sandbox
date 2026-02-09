# Configuration Reference - Helm Kafka Adapter

This Helm chart deploys the ONIX Kafka adapter for Kubernetes. The adapter configuration is templated from `values.yaml` with dynamic service name replacement and injected via Kubernetes ConfigMaps.

## Configuration Source

The adapter configuration is based on the Kafka adapter configurations documented in:
- **[onix-adaptor-kafka/config.md](../onix-adaptor-kafka/config.md)** - Complete Kafka adapter configuration reference

## Configuration Files

- **Values File**: `values.yaml` (base configuration)
- **BAP Values**: `values-bap.yaml` (BAP-specific overrides)
- **BPP Values**: `values-bpp.yaml` (BPP-specific overrides)
- **ConfigMap Template**: `templates/configmap.yaml` (generates Kubernetes ConfigMaps with dynamic replacements)

## How Configuration Works

1. **Adapter Configuration**: Defined in `values.yaml` under `config.adapter`
2. **Routing Configuration**: Defined in `values.yaml` under `config.routing.caller` and `config.routing.receiver`
3. **Dynamic Service Replacement**: Helm template automatically replaces service addresses:
   - Kafka broker: `kafka:9092` → `<fullname>-kafka:<port>`
   - Redis address: `redis-bap:6379` → `<fullname>-redis-<component>:<port>`
4. **ConfigMap Generation**: Helm template generates two ConfigMaps:
   - `<release-name>-<component>-config`: Contains routing YAML files
   - `<release-name>-<component>-adapter`: Contains `adapter.yaml` with replaced service names

## Helm-Specific Overrides

The Helm chart applies the following service name replacements automatically:

### Service Name Replacements

| Original Value | Helm Replacement | Description |
|----------------|------------------|-------------|
| `kafka:9092` | `<fullname>-kafka:<port>` | Kafka broker address based on Helm release name |
| `redis-bap:6379` | `<fullname>-redis-<component>:<port>` | Redis address for BAP component |
| `redis-bpp:6379` | `<fullname>-redis-<component>:<port>` | Redis address for BPP component |

### Dynamic Replacement Logic

The ConfigMap template performs the following replacements:

```yaml
{{- $fullname := include "onix-kafka.fullname" . }}
{{- $redisHost := printf "%s-redis-%s" $fullname .Values.component }}
{{- $redisPort := int .Values.redis.service.port }}
{{- $redisAddr := printf "%s:%d" $redisHost $redisPort }}
{{- $kafkaBroker := .Values.kafka.broker }}
{{- if not $kafkaBroker }}
{{- $kafkaPort := int .Values.kafka.service.port }}
{{- $kafkaBroker = printf "%s-kafka:%d" $fullname $kafkaPort }}
{{- end }}
{{- $adapterConfig = $adapterConfig | replace "redis-bap:6379" $redisAddr }}
{{- $adapterConfig = $adapterConfig | replace "redis-bpp:6379" $redisAddr }}
{{- $adapterConfig = $adapterConfig | replace "kafka:9092" $kafkaBroker }}
```

### ConfigMap Structure

**ConfigMap 1: Routing Configuration**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "onix-kafka.fullname" . }}-{{ .Values.component }}-config
data:
  bapTxnCaller-routing.yaml: |  # or bppTxnCaller-routing.yaml
    {{ .Values.config.routing.caller | indent 4 }}
  bapTxnReciever-routing.yaml: |  # or bppTxnReciever-routing.yaml
    {{ .Values.config.routing.receiver | indent 4 }}
```

**ConfigMap 2: Adapter Configuration (with replacements)**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "onix-kafka.fullname" . }}-{{ .Values.component }}-adapter
data:
  adapter.yaml: |
    {{ $adapterConfig | indent 4 }}  # With service name replacements applied
```

## Configuration Values

### Base Configuration (`values.yaml`)

| Key | Description |
|-----|-------------|
| `component` | Component type: `bap` or `bpp` |
| `fullnameOverride` | Override for service naming (default: `onix` for shared Kafka) |
| `image.repository` | Docker image repository |
| `image.tag` | Docker image tag |
| `service.port` | Kubernetes service port (8001 for BAP, 8002 for BPP) |
| `kafka.enabled` | Enable Kafka deployment (true for BAP, false for BPP) |
| `kafka.broker` | Kafka broker address (empty = auto-generate from fullname) |
| `kafka.service.port` | Kafka service port (default: 9092) |
| `redis.enabled` | Enable Redis deployment |
| `redis.service.port` | Redis service port (default: 6379) |
| `config.adapter` | Complete adapter.yaml content (multiline string) |
| `config.routing.caller` | Caller routing YAML content |
| `config.routing.receiver` | Receiver routing YAML content |

### BAP-Specific Configuration (`values-bap.yaml`)

| Key | Value | Description |
|-----|-------|-------------|
| `component` | `bap` | Component type |
| `fullnameOverride` | `onix` | Shared Kafka service name |
| `service.port` | `8001` | BAP service port |
| `kafka.enabled` | `true` | BAP release includes Kafka |
| `kafkaUI.enabled` | `true` | BAP release includes Kafka UI |
| `config.adapter` | BAP Kafka adapter.yaml content | See [onix-adaptor-kafka/config.md](../onix-adaptor-kafka/config.md) |

### BPP-Specific Configuration (`values-bpp.yaml`)

| Key | Value | Description |
|-----|-------|-------------|
| `component` | `bpp` | Component type |
| `fullnameOverride` | `onix` | Shared Kafka service name (same as BAP) |
| `service.port` | `8002` | BPP service port |
| `kafka.enabled` | `false` | BPP uses shared Kafka from BAP release |
| `kafkaUI.enabled` | `false` | BPP uses shared Kafka UI from BAP release |
| `kafka.broker` | `""` | Auto-detect from BAP release (onix-kafka:9092) |
| `config.adapter` | BPP Kafka adapter.yaml content | See [onix-adaptor-kafka/config.md](../onix-adaptor-kafka/config.md) |

## Service Names

When deployed with `fullnameOverride=onix`, services are named:

| Service Type | Service Name | Description |
|-------------|--------------|-------------|
| **Kafka Broker** | `onix-kafka` | Shared Kafka service (from BAP release) |
| **Kafka UI** | `onix-kafka-ui` | Shared Kafka UI service (from BAP release) |
| **BAP Service** | `onix-bap-service` | BAP adapter HTTP service |
| **BPP Service** | `onix-bpp-service` | BPP adapter HTTP service |
| **Redis BAP** | `onix-redis-bap` | Redis cache for BAP adapter |
| **Redis BPP** | `onix-redis-bpp` | Redis cache for BPP adapter |

## Deployment Example

```bash
# Deploy BAP (includes Kafka and Kafka UI)
helm install onix-bap ./helm-kafka \
  -f ./helm-kafka/values-bap.yaml \
  --set fullnameOverride=onix

# Deploy BPP (uses shared Kafka from BAP)
helm install onix-bpp ./helm-kafka \
  -f ./helm-kafka/values-bpp.yaml \
  --set fullnameOverride=onix
```

## Configuration Override

To override configuration values:

```bash
# Override Kafka broker address
helm install onix-bpp ./helm-kafka \
  -f ./helm-kafka/values-bpp.yaml \
  --set kafka.broker=external-kafka:9092

# Override Redis address in adapter config
helm install onix-bap ./helm-kafka \
  -f ./helm-kafka/values-bap.yaml \
  --set redis.service.port=6380
```

## Kafka Topic Configuration

Kafka topics are auto-created by the adapter when `admin.enabled` is set to `"on"` in the publisher/consumer configuration.

### BAP Topics
- **Consumer Topics**: `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
- **Publisher Topics**: `bap.on_discover`, `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support`, `bap.on_default`

### BPP Topics
- **Consumer Topics**: `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`
- **Publisher Topics**: `bpp.discover`, `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support`, `bpp.default`

## Viewing Generated Configuration

After deployment, view the generated ConfigMaps:

```bash
# View adapter ConfigMap
kubectl get configmap onix-bap-adapter -o yaml

# View routing ConfigMap
kubectl get configmap onix-bap-config -o yaml

# Verify service name replacements
kubectl get configmap onix-bap-adapter -o jsonpath='{.data.adapter\.yaml}' | grep -E "(kafka|redis)"
```

## Additional Resources

- **[onix-adaptor-kafka/config.md](../onix-adaptor-kafka/config.md)**: Complete Kafka adapter configuration reference
- **[helm-kafka/README.md](./README.md)**: Helm Kafka deployment guide
- **[values.yaml](./values.yaml)**: Base Helm values file
- **[values-bap.yaml](./values-bap.yaml)**: BAP-specific values
- **[values-bpp.yaml](./values-bpp.yaml)**: BPP-specific values
