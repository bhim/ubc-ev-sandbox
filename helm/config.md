# Configuration Reference - Helm REST API Adapter

This Helm chart deploys the ONIX REST API adapter for Kubernetes. The adapter configuration is templated from `values.yaml` and injected via Kubernetes ConfigMaps.

## Configuration Source

The adapter configuration is based on the REST API adapter configurations documented in:
- **[onix-adaptor/config.md](../onix-adaptor/config.md)** - Complete REST API adapter configuration reference

## Configuration Files

- **Values File**: `values.yaml` (base configuration)
- **BAP Values**: `values-bap.yaml` (BAP-specific overrides)
- **BPP Values**: `values-bpp.yaml` (BPP-specific overrides)
- **ConfigMap Template**: `templates/configmap.yaml` (generates Kubernetes ConfigMaps)

## How Configuration Works

1. **Adapter Configuration**: Defined in `values.yaml` under `config.adapter`
2. **Routing Configuration**: Defined in `values.yaml` under `config.routing.caller` and `config.routing.receiver`
3. **ConfigMap Generation**: Helm template generates two ConfigMaps:
   - `<release-name>-<component>-config`: Contains routing YAML files
   - `<release-name>-<component>-adapter`: Contains `adapter.yaml`

## Helm-Specific Overrides

The Helm chart applies the following service name replacements automatically:

### Service Name Replacements

| Original Value | Helm Replacement | Description |
|----------------|------------------|-------------|
| `redis-onix-bap:6379` | `<fullname>-redis-<component>:<port>` | Redis address based on Helm release name |
| `redis-onix-bpp:6379` | `<fullname>-redis-<component>:<port>` | Redis address based on Helm release name |
| `http://mock-registry:3030` | Configurable via `config.registryUrl` | Registry URL override |

### ConfigMap Structure

**ConfigMap 1: Routing Configuration**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "onix-api-monolithic.fullname" . }}-{{ .Values.component }}-config
data:
  bap_caller_routing.yaml: |  # or bpp_caller_routing.yaml
    {{ .Values.config.routing.caller | indent 4 }}
  bap_receiver_routing.yaml: |  # or bpp_receiver_routing.yaml
    {{ .Values.config.routing.receiver | indent 4 }}
```

**ConfigMap 2: Adapter Configuration**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "onix-api-monolithic.fullname" . }}-{{ .Values.component }}-adapter
data:
  adapter.yaml: |
    {{ .Values.config.adapter | indent 4 }}
```

## Configuration Values

### Base Configuration (`values.yaml`)

| Key | Description |
|-----|-------------|
| `component` | Component type: `bap` or `bpp` |
| `image.repository` | Docker image repository |
| `image.tag` | Docker image tag |
| `service.port` | Kubernetes service port (8001 for BAP, 8002 for BPP) |
| `config.adapter` | Complete adapter.yaml content (multiline string) |
| `config.routing.caller` | Caller routing YAML content |
| `config.routing.receiver` | Receiver routing YAML content |
| `config.registryUrl` | Registry service URL (default: `http://mock-registry:3030`) |

### BAP-Specific Configuration (`values-bap.yaml`)

| Key | Value | Description |
|-----|-------|-------------|
| `component` | `bap` | Component type |
| `service.port` | `8001` | BAP service port |
| `config.adapter` | BAP adapter.yaml content | See [onix-adaptor/config.md](../onix-adaptor/config.md) |

### BPP-Specific Configuration (`values-bpp.yaml`)

| Key | Value | Description |
|-----|-------|-------------|
| `component` | `bpp` | Component type |
| `service.port` | `8002` | BPP service port |
| `config.adapter` | BPP adapter.yaml content | See [onix-adaptor/config.md](../onix-adaptor/config.md) |

## Service Names

When deployed, services are named based on the Helm release name:

| Service Type | Service Name Pattern | Example |
|-------------|---------------------|---------|
| **BAP Service** | `<release-name>-service` | `onix-bap-service` |
| **BPP Service** | `<release-name>-service` | `onix-bpp-service` |
| **Redis BAP** | `<release-name>-redis-bap` | `onix-bap-redis-bap` |
| **Redis BPP** | `<release-name>-redis-bpp` | `onix-bpp-redis-bpp` |

## Deployment Example

```bash
# Deploy BAP
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml

# Deploy BPP
helm install onix-bpp ./helm \
  -f ./helm/values-bpp.yaml
```

## Configuration Override

To override configuration values:

```bash
# Override registry URL
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set config.registryUrl=http://custom-registry:3030

# Override Redis address in adapter config
helm install onix-bap ./helm \
  -f ./helm/values-bap.yaml \
  --set config.adapter="<custom adapter.yaml content>"
```

## Viewing Generated Configuration

After deployment, view the generated ConfigMaps:

```bash
# View adapter ConfigMap
kubectl get configmap onix-bap-adapter -o yaml

# View routing ConfigMap
kubectl get configmap onix-bap-config -o yaml
```

## Additional Resources

- **[onix-adaptor/config.md](../onix-adaptor/config.md)**: Complete REST API adapter configuration reference
- **[helm/README.md](./README.md)**: Helm deployment guide
- **[values.yaml](./values.yaml)**: Base Helm values file
- **[values-bap.yaml](./values-bap.yaml)**: BAP-specific values
- **[values-bpp.yaml](./values-bpp.yaml)**: BPP-specific values
