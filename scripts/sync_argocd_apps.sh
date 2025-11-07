#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

usage() {
  echo "Usage: $0 \"<commit message>\""
  echo "Example: $0 \"Upgrade foo-app to v1.2.3\""
  exit 1
}

# Require exactly one argument
if [[ $# -ne 1 ]]; then
  usage
fi

COMMIT_MSG="$1"

# Stage ArgoCD app changes
git add apps/

# Commit only if there are changes
if ! git diff --cached --quiet; then
  git commit -m "Sync ArgoCD apps for: ${COMMIT_MSG}"
  git push origin main
else
  echo "No changes detected in apps/ — skipping commit."
fi

# Start port-forward in the background
kubectl -n argocd port-forward svc/argocd-server 8080:443 >/dev/null 2>&1 &

# Log in to ArgoCD
argocd login localhost:8080 \
  --username admin \
  --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)" \
  --insecure

# Sync the app-of-apps
argocd app sync argocd/app-of-apps --prune