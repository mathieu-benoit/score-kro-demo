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

# --- Install Metrics Server ---
echo "⏳ Installing Metrics Server..."
METRICS_SERVER_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest | jq -r .tag_name)

kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER_VERSION}/components.yaml"

# Patch args for kind (no kubelet TLS + preferred address types)
# (adds flags; safe to run multiple times)
kubectl -n kube-system patch deploy metrics-server --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"}
]' || true

echo "✅ Metrics Server successfully deployed"

# --- Install Gateway API + NGINX Gateway Fabric ---
echo "⏳ Installing Gateway API..."
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

# --- Install kro v0.6.3 (pinned version) ---
echo "⏳ Installing Kro..."
KRO_VERSION="0.6.3"

helm upgrade kro oci://registry.k8s.io/kro/charts/kro \
  --namespace kro \
  --create-namespace \
  --install \
  --version "${KRO_VERSION}"

echo "✅ Kro successfully deployed"

# --- Install KCC ---
# For now, we don't install KCC per se, we just apply the Memorystore (Redis) CRD needed to deploy our own Workload CR.
echo "⏳ Installing KCC..."
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-config-connector/refs/heads/master/crds/redis_v1beta1_redisinstance.yaml

echo "✅ KCC's Memorystore CRD successfully deployed"

echo ""
echo "✅ Setup complete: Gateway API, NGINX Gateway Fabric and kro are installed."
echo ""
