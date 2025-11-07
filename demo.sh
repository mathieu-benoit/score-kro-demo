#!/bin/bash

code() { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $*; }

# setup
if [ ! -f demo-magic.sh ]; then
    curl -LO https://github.com/paxtonhare/demo-magic/raw/master/demo-magic.sh
fi
. demo-magic.sh -d #-n
clear

# Demo setup
kubectl apply -f kro/workload.yaml
clear

# Demo #1
pe "echo \"Demo #1 - Developer Focus through Abstraction with Kro\""
pe "echo \"What is Kro?\""
pe "code images/demo-6.png"
pe "code images/demo-0.png" #light version
pe "code -g kro/workload.yaml:1"
pe "code podinfo/gen-man-by-dev-podinfo-minimal-setup.yaml"
pe "code images/demo-0.png" #current version
cp podinfo/gen-man-by-dev-podinfo.yaml apps/gen-man-by-dev-podinfo.yaml
pe "echo \"GitOps Deployment - Demo 1\""
./scripts/sync_argocd_apps.sh demo-1 >/dev/null 2>&1""
pe "kubectl get workload,all,hpa,netpol,sa -n podinfo-kro"

# Demo #2
pe "echo \"Demo #2 - Platform Infra Standardization (Redis) with Kro\""
pe "code images/demo-2-redis-in-cluster.png"
pe "code podinfo-with-redis/gen-man-by-dev-podinfo-minimal-setup.yaml"
cp podinfo-with-redis/gen-man-by-dev-podinfo-redis.yaml apps/gen-man-by-dev-podinfo.yaml
pe "echo \"GitOps Deployment - Demo 2\""
./scripts/sync_argocd_apps.sh demo-2 >/dev/null 2>&1""
pe "kubectl get workload,all,hpa,netpol,sa -n podinfo-kro"
pe "echo \"What about Redis outside of the cluster, hosted by a Cloud Provider for example?\""
pe "code images/demo-2-redis-in-gcp.png"
pe "code -g kro/workload.yaml:421"
pe "code podinfo-with-redis/gen-man-by-dev-podinfo-minimal-setup-gcp.yaml"

# Demo #3
pe "echo \"Demo #3 - Extend Abstraction with Flexibility with Kro & Score\""
pe "code images/demo-2.png"
pe "code podinfo-with-redis/score-minimal.yaml"
pe "code score-k8s/kro-workload-patch-template.tpl"
pe "score-k8s init \
    --no-sample \
    --no-default-provisioners \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-k8s/namespace-pss-restricted.tpl \
    --patch-templates ./score-k8s/kro-workload-patch-template.tpl \
    --provisioners ./score-k8s/kro-provisioners.yaml"
pe "score-k8s generate podinfo/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:6.9.2 \
    --namespace podinfo-score \
    --generate-namespace \
    --override-property containers.podinfo.variables.PODINFO_UI_MESSAGE=\"Hello, from ArgoCD, Kro and Score\" \
    --output apps/gen-by-score-podinfo.yaml"
pe "./scripts/sync_argocd_apps.sh demo-3"

# Demo #4
pe "echo \"Demo #4 - Bridging Inner and Outer Loops - Score with Docker Compose\""
pe "code images/demo-4-docker-compose.png"
pe "score-compose init \
    --no-sample \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-compose/unprivileged.tpl \
	--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/horizontal-pod-autoscaler/score-compose/10-hpa.provisioners.yaml"
pe "score-compose generate podinfo-with-redis/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:6.9.2 \
    --override-property containers.podinfo.variables.PODINFO_UI_MESSAGE=\"Hello, from Compose and Score, with Redis\""
pe "docker compose up --build -d --wait"