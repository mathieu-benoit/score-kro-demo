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

# =====================================================================
#                       Metrics Server (for HPA)
# =====================================================================
METRICS_SERVER_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest | jq -r .tag_name)

kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER_VERSION}/components.yaml"

# Patch args for kind (no kubelet TLS + preferred address types)
# (adds flags; safe to run multiple times)
kubectl -n kube-system patch deploy metrics-server --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"}
]' || true


# --- Install kro v0.4.1 (pinned version) ---
KRO_VERSION="0.4.1"

helm install kro oci://ghcr.io/kro-run/kro/kro \
  --namespace kro \
  --create-namespace \
  --version "${KRO_VERSION}"

kubectl rollout status -n kro deploy/kro


echo "✅ Setup complete: Gateway API, NGINX Gateway Fabric, and kro v${KRO_VERSION} are installed."


# Helm repo (argo) + pinned chart version
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

ARGOCD_CHART_VERSION="8.5.3"
ARGOCD_NS="argocd"

helm install argocd argo/argo-cd \
  --namespace "${ARGOCD_NS}" \
  --create-namespace \
  --version "${ARGOCD_CHART_VERSION}" \
  --set server.service.type=ClusterIP

echo ""
echo "✅ Setup complete:"
echo "   - Argo CD installed (namespace: ${ARGOCD_NS}, chart: ${ARGOCD_CHART_VERSION})"
echo ""

echo "🔐 Argo CD admin password:"
kubectl -n "${ARGOCD_NS}" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

cat <<'TIP'

To access the Argo CD UI locally:
  kubectl -n argocd port-forward svc/argocd-server 8080:443
Then open: https://localhost:8080
Login:
  username: admin
  password: (printed above)

TIP