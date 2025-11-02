#!/bin/bash
set -o errexit
set -o pipefail

kubectl -n argocd port-forward svc/argocd-server 8080:443 >/dev/null 2>&1 &

argocd login localhost:8080 \
  --username admin \
  --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)" \
  --insecure


argocd app sync argocd/app-of-apps
