# EmELand Helm Charts

Production Helm charts for deploying the EmELand stack on Kubernetes.

Charts are published as OCI artifacts to [GitHub Container Registry](https://github.com/emeland-io/emeland-helm/pkgs/container/emeland-helm%2Femeland) (`ghcr.io/emeland-io/emeland-helm`).

## Charts

| Chart | Purpose |
|-------|---------|
| `emeland-crd` | CRDs required by the Kubernetes sensor |
| `emeland` | Web UI server, filter, CLI tools, git sensor, and k8s sensor |

## Quick start

Install CRDs first, then the main stack. Replace `0.1.0` with the [release version](https://github.com/emeland-io/emeland-helm/releases) you want.

```bash
export CHART_VERSION=0.1.0
export HELM_OCI_REPO=oci://ghcr.io/emeland-io/emeland-helm

helm upgrade --install emeland-crd "${HELM_OCI_REPO}/emeland-crd" \
  --version "${CHART_VERSION}" \
  --namespace emeland \
  --create-namespace

helm upgrade --install emeland "${HELM_OCI_REPO}/emeland" \
  --version "${CHART_VERSION}" \
  --namespace emeland \
  --create-namespace
```

List published chart versions:

```bash
helm show chart oci://ghcr.io/emeland-io/emeland-helm/emeland --versions
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                                  │
│                                                                      │
│  ┌─────────────────┐                                                 │
│  │  gitsensor      │  watches external Git repos (optional)          │
│  │  (optional)     │                                                 │
│  └────────┬────────┘                                                 │
│           │ POST /api/events/push                                    │
│           ▼                                                          │
│  ┌─────────────────┐   POST /api/events/push   ┌─────────────────┐   │
│  │  k8s-sensor     │──────────────────────────▶│  filter         │   │
│  │  (controller)   │                           │  (modelsrv)     │   │
│  └─────────────────┘                           └────────┬────────┘   │
│                                                         │            │
│                                                         ▼            │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │  web UI server (modelsrv-web-ui-server)                      │    │
│  │  • Aggregates events into the landscape model                │    │
│  │  • Exposes REST API and Web UI                               │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌─────────────────┐                                                 │
│  │  tools          │  emelandctl CLI (kubectl exec)                  │
│  └─────────────────┘                                                 │
└──────────────────────────────────────────────────────────────────────┘
```

## Components

The `emeland` chart deploys:

- **Web UI server** (`modelsrv-web-ui-server`) — central modelsrv with Web UI
- **Filter** (`modelsrv`) — phase0 integrity filter between sensors and server
- **Tools** (`emelandctl`) — interactive CLI shell pod
- **Git sensor** (`modelsrv-git-sensor`, optional) — watches external Git repositories
- **K8s sensor** (`modelsrv-k8s-sensor` sub-chart) — watches cluster resources
- **CRDs** (`modelsrv-k8s-crd` sub-chart) — custom resource definitions for the sensor

All workload names are prefixed `emeland-*` via `fullnameOverride`.

## Container images

The chart pulls the following images from `ghcr.io/emeland-io` (tags are set in [`emeland/values.yaml`](emeland/values.yaml)):

| Image | Component |
|-------|-----------|
| `ghcr.io/emeland-io/modelsrv-web-ui-server` | Web UI server |
| `ghcr.io/emeland-io/modelsrv` | Filter |
| `ghcr.io/emeland-io/emelandctl` | CLI tools |
| `ghcr.io/emeland-io/modelsrv-git-sensor` | Git sensor (optional) |
| `ghcr.io/emeland-io/modelsrv-k8s-sensor` | Kubernetes sensor |

The `emeland-crd` chart installs CRDs only and does not deploy a container image.

## Configuration

Pass a values file when installing or upgrading:

```bash
helm upgrade --install emeland oci://ghcr.io/emeland-io/emeland-helm/emeland \
  --version "${CHART_VERSION}" \
  --namespace emeland \
  --values my-values.yaml
```

Key values:

| Value | Description |
|-------|-------------|
| `server.noAuth` | Disable OIDC auth (default: `false`) |
| `gitsensor.enabled` | Enable git sensor (default: `false`) |
| `gitsensor.repos` | External Git repositories to watch |
| `gitsensor.existingSecret` | Pre-created Secret with SSH deploy key |
| `modelsrv-k8s-sensor.enabled` | Enable Kubernetes sensor |
| `ingress.enabled` / `httpRoute.enabled` | Expose the web UI server |

See [`emeland/values.yaml`](emeland/values.yaml) for defaults.

### Git sensor

When enabling the git sensor, configure external repositories and provide a deploy key:

```yaml
gitsensor:
  enabled: true
  existingSecret: emeland-gitsensor-deploy-key
  repos:
    - type: github
      repo: git@github.com:org/landscape.git
      branch: main
      checkoutDir: /work/checkout/landscape
      paths:
        - manifests/
```

Create the deploy key Secret separately (recommended for production):

```bash
kubectl create secret generic emeland-gitsensor-deploy-key \
  --from-file=id_ed25519=./deploy_key \
  --from-file=id_ed25519.pub=./deploy_key.pub \
  -n emeland
```

## Publishing

Charts are published to GHCR automatically when a `v*` tag is pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## Differences from the demo stack

This chart is derived from [emeland-demo-stack-chart](https://github.com/emeland-io/emeland-demo-stack-chart) with demo-only components removed:

- No in-cluster git server or baked test data
- No Prometheus/Grafana stack
- Auth enabled by default
- Git sensor connects to external repositories only
