# mNi installation

This repository defines the complete mNi production control plane. Each
top-level directory under `config/` owns one service responsibility and keeps
its controller, UI, and service-specific infrastructure in child
Kustomizations. The child boundary is intentional: upstream manifests commonly
use generic image names such as `controller:latest`, so image transforms must
not leak into sibling components.

## Responsibilities

- `platform`: cert-manager, dependency-controller, and the shared Kata Helm values.
- `auth`: Anchorage, auth-controller, and auth-ui.
- `api-gateway`: api-gateway.
- `vpc`: Juneau, vpc-controller, and vpc-ui.
- `bs`: bs-controller and bs-ui.
- `vm`: KubeVirt, CDI, snapshot-controller, vm-controller, and vm-ui.
- `ctr`: ctr-controller and ctr-ui. Uses the shared Kata runtime.
- `vpn`: Kodiak, vpn-controller, and vpn-ui.
- `cs`: cs-controller and cs-ui. Uses the shared Kata runtime.
- `lb`: Envoy Gateway, lb-controller, lb-ui, and GatewayClass.
- `k8s`: Cluster API, Kamaji/CAPK, CAAPH, CAPMNI, CAA, k8s-controller,
  and k8s-ui. Serverless workers use the shared Kata runtime.
- `bootstrap`: CRs that must be applied after their owning CRDs/controllers.

`config/default` renders every Kustomize-managed service. Helm-managed Kata,
Envoy Gateway, and Kamaji are represented by Argo CD Applications.

## Argo CD

Install the pinned Argo CD release, wait for it to become ready, and register
the Applications:

```sh
kubectl apply -k argocd/install
kubectl -n argocd rollout status deployment/argocd-server --timeout=10m
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=10m
kubectl apply -k argocd
```

No Application has `syncPolicy.automated`; registering or updating an
Application does not deploy workloads. Argo CD only calculates and displays
the desired/live diff.

To deploy all services explicitly and wait for each dependency to become
Healthy before continuing:

```sh
./argocd/sync.sh
```

The same Applications can be synced individually from the Argo CD UI. Keep the
order used by `sync.sh` when upgrading platform or service dependencies.

Application sources track `v2/main`. For validation before merge, temporarily
change `targetRevision` to the test branch and restore it before merging.

## Cluster-specific inputs

The repository intentionally does not copy E2E host names, OAuth clients,
self-signed certificates, BGP peers, or test SMTP settings. Supply those
production values from the environment-specific configuration before syncing.

Managed Kubernetes additionally requires the
`kamaji-system/management-kubeconfig` Secret with kubeconfig data in the
`value` key. Kata nodes must be labeled `mnicloud.jp/kata=true` and provide
hardware virtualization.
