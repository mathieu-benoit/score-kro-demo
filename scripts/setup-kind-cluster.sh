#!/bin/bash
set -o errexit

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

GATEWAY_API_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/latest | jq -r .tag_name)
kubectl apply \
    -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml

helm install ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric \
    --create-namespace \
    -n nginx-gateway \
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

# --- Install kro v0.4.1 (pinned version) ---
KRO_VERSION="0.4.1"

helm install kro oci://ghcr.io/kro-run/kro/kro \
  --namespace kro \
  --create-namespace \
  --version "${KRO_VERSION}"

kubectl rollout status -n kro deploy/kro --timeout=120s


echo "✅ Setup complete: Gateway API, NGINX Gateway Fabric, and kro v${KRO_VERSION} are installed."