#!/bin/sh
set -e

# Load configuration
. /config/config.env

# Apply node labels
kubectl label node -lbeta.kubernetes.io/os=linux kubernetes.io/os=linux --overwrite
kubectl label node -lnode-role.kubernetes.io/control-plane kube-ovn/role=master --overwrite
kubectl label node -lovn.kubernetes.io/ovs_dp_type!=userspace ovn.kubernetes.io/ovs_dp_type=kernel --overwrite

# Add helm repos and install components
helm repo add kubeovn https://kubeovn.github.io/kube-ovn/
helm repo update

# Install Kube-OVN
helm upgrade --install kube-ovn kubeovn/kube-ovn \
  --namespace kube-system \
  --set MASTER_NODES=${MASTER_IP} \
  --set func.ENABLE_LB_SVC=true \
  --set func.ENABLE_TPROXY=true

# Install Multus
curl -L https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml | \
kubectl apply -f -

# Format exclude IPs
FORMATTED_EXCLUDE_IPS=""
oldIFS=$IFS
IFS=","
for range in $EXCLUDE_IPS; do
  FORMATTED_EXCLUDE_IPS="${FORMATTED_EXCLUDE_IPS}  - $range"$'\n'
done
IFS=$oldIFS

# Create external network configuration
cat > temp.yaml << EOF
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: ovn-vpc-external-network
spec:
  protocol: IPv4
  provider: ovn-vpc-external-network.kube-system
  cidrBlock: ${EXTERNAL_CIDR}
  gateway: ${EXTERNAL_GATEWAY}
  excludeIps:
${FORMATTED_EXCLUDE_IPS}
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovn-vpc-external-network
  namespace: kube-system
spec:
  config: '{
    "cniVersion": "0.3.0",
    "type": "macvlan",
    "master": "${EXTERNAL_NETWORK_INTERFACE}",
    "mode": "bridge",
    "ipam": {
      "type": "kube-ovn",
      "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
      "provider": "ovn-vpc-external-network.kube-system"
    }
  }'
EOF
kubectl apply -f temp.yaml
rm temp.yaml
