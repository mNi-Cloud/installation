# How to install

1. Create network-config.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: network-config
  namespace: kube-system
data:
  config.env: |
    MASTER_IP=192.168.0.100
    EXTERNAL_CIDR=192.168.0.0/24
    EXTERNAL_GATEWAY=192.168.0.1
    EXCLUDE_IPS=192.168.0.100..192.168.0.254
    EXTERNAL_NETWORK_INTERFACE=eth0
```

2. Deploy CNI & mNi Operator
```bash
kubectl apply -f https://raw.githubusercontent.com/mni-cloud/installation/main/deploy/mni-installer.yaml
```



3. Install dependencies
```bash
kubectl apply -f https://raw.githubusercontent.com/mni-cloud/installation/main/deploy/components.yaml
```

4. Install the services you need
Examle
```bash
apiVersion: operator.mnicloud.jp/v1alpha1
kind: Service
metadata:
  name: vpc
spec:
  image: ghcr.io/mni-cloud/vpc:latest
  appVersion: 1.0.0
  # You may specify secrets to pull the image
  # imagePullSecrets:
  #   - name: regcred
```
