#!/bin/bash
set -o errexit
set -o pipefail

# Helm repo (argo) + pinned chart version
echo "⏳ Installing Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

ARGOCD_CHART_VERSION="8.5.3"
ARGOCD_NS="argocd"

helm upgrade argocd argo/argo-cd \
  --namespace "${ARGOCD_NS}" \
  --create-namespace \
  --install \
  --version "${ARGOCD_CHART_VERSION}" \
  --set server.service.type=ClusterIP

kubectl rollout status -n "${ARGOCD_NS}" deploy/argocd-server --timeout=120s

kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-kro
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    path: ./kro
    repoURL: https://github.com/mathieu-benoit/score-kro-demo.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      enabled: true
      prune: true
      selfHeal: true
    retry:
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m0s
      limit: 5
    syncOptions:
    - Validate=false
    - PruneLast=true
    - RespectIgnoreDifferences=true
    - ServerSideApply=true
    - Replace=true
EOF

kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      recurse: true
    path: ./apps
    repoURL: https://github.com/mathieu-benoit/score-kro-demo.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      enabled: true
      prune: true
      selfHeal: true
    retry:
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m0s
      limit: 5
    syncOptions:
    - Validate=false
    - PruneLast=true
    - RespectIgnoreDifferences=true
    - ServerSideApply=true
    - Replace=true
EOF

echo "Successfully deployed Argo CD"
echo ""
echo "🔐 Argo CD user: admin and admin password:"
kubectl -n "${ARGOCD_NS}" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

echo ""
echo "✅ Setup complete: Metrics Server and Argo CD are installed."
echo ""