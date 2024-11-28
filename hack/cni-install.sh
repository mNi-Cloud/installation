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
helm repo add cilium https://helm.cilium.io/
helm repo update

# Install Kube-OVN
helm upgrade --install kube-ovn kubeovn/kube-ovn \
  --namespace kube-system \
  --set MASTER_NODES=${MASTER_IP} \
  --set func.ENABLE_NP=false \
  --set func.ENABLE_LB_SVC=true \
  --set func.ENABLE_TPROXY=true \
  --set cni_conf.CNI_CONFIG_PRIORITY=10

# Create CNI ConfigMap
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cni-configuration
  namespace: kube-system
data:
  cni-config: |-
    {
      "name": "generic-veth",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "kube-ovn",
          "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
          "ipam": {
            "type": "kube-ovn",
            "server_socket": "/run/openvswitch/kube-ovn-daemon.sock"
          }
        },
        {
          "type": "portmap",
          "snat": true,
          "capabilities": {"portMappings": true}
        },
        {
          "type": "cilium-cni"
        }
      ]
    }
EOF

# Install Cilium
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --set operator.replicas=1 \
  --set cni.chainingMode=generic-veth \
  --set cni.customConf=true \
  --set cni.configMap=cni-configuration \
  --set routingMode=native \
  --set enableIPv4Masquerade=false \
  --set devices="eth+ ovn0 genev_sys_6081 vxlan_sys_4789" \
  --set enableIdentityMark=false \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

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

# Clean up installation resources
echo "Cleaning up installation resources..."
kubectl -n kube-system delete daemonset mni-installer
kubectl -n kube-system delete configmap network-install
kubectl -n kube-system delete configmap network-config
kubectl delete clusterrolebinding mni-installer
kubectl delete clusterrole mni-installer
kubectl -n kube-system delete serviceaccount mni-installer