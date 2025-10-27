#!/bin/bash
set -o errexit
set -o pipefail

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 31000
    hostPort: 80
    protocol: TCP
EOF

echo "✅ Kind cluster successfully created"

# --- Install Gateway API + NGINX Gateway Fabric ---
GATEWAY_API_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/latest | jq -r .tag_name)
kubectl apply \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml

helm upgrade ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric \
    --create-namespace \
    -n nginx-gateway \
    --install \
    --set service.type=NodePort \
    --set-json 'service.ports=[{"port":80,"nodePort":31000}]'

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF

echo "✅ Gateway API successfully deployed"

# --- Install kro v0.5.0 (pinned version) ---
KRO_VERSION="0.5.0"

helm upgrade kro oci://registry.k8s.io/kro/charts/kro \
  --namespace kro \
  --create-namespace \
  --install \
  --version "${KRO_VERSION}"

echo "✅ Kro successfully deployed"

# --- Install latest Config Connector (KCC) version  ---
gcloud storage cp gs://configconnector-operator/latest/release-bundle.tar.gz release-bundle.tar.gz
tar zxvf release-bundle.tar.gz
kubectl apply -f operator-system/configconnector-operator.yaml
rm -rf operator-system
rm release-bundle.tar.gz
rm -rf samples

echo "✅ KCC successfully deployed"

echo ""
echo "✅ Setup complete: Gateway API, NGINX Gateway Fabric, kro and KCC are installed."
echo ""