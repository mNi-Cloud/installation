#!/usr/bin/env bash
set -euo pipefail

command -v argocd >/dev/null
command -v kubectl >/dev/null

if ! kubectl get nodes -l mnicloud.jp/kata=true -o name | grep -q .; then
  echo "no node is labeled mnicloud.jp/kata=true" >&2
  exit 1
fi

sync_and_wait() {
  local app=$1
  echo "==> syncing ${app}"
  argocd app sync "${app}"
  argocd app wait "${app}" --sync --health --timeout 1200
}

# This script is the explicit deployment action. Applications have no
# automated sync policy; Git changes are only shown as OutOfSync until this is
# invoked (or Sync is clicked in the Argo CD UI).
sync_and_wait mni-platform
sync_and_wait mni-kata
sync_and_wait mni-auth
sync_and_wait mni-api-gateway
sync_and_wait mni-vpc
sync_and_wait mni-bs
sync_and_wait mni-vm
sync_and_wait mni-ctr
sync_and_wait mni-vpn
sync_and_wait mni-cs
sync_and_wait mni-lb-envoy-gateway
sync_and_wait mni-lb
sync_and_wait mni-k8s-kamaji-crds
sync_and_wait mni-k8s-kamaji

if ! kubectl -n kamaji-system get secret management-kubeconfig \
  -o jsonpath='{.data.value}' | grep -q .; then
  echo "kamaji-system/management-kubeconfig is missing data key 'value'" >&2
  exit 1
fi

sync_and_wait mni-k8s
sync_and_wait mni-bootstrap
