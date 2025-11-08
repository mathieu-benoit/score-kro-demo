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
pe "code images/kro-rgd.png"
pe "code images/setup-overview-0.png" #light version
pe "code -g kro/workload.yaml:1"
pe "code podinfo/gen-man-by-dev-podinfo-minimal-setup.yaml"
pe "code images/demo-01.png" #current version
cp podinfo/gen-man-by-dev-podinfo.yaml apps/gen-man-by-dev-podinfo.yaml
pe "echo \"GitOps Deployment - Demo 1\""
./scripts/sync_argocd_apps.sh demo-1 >/dev/null 2>&1
pe "kubectl get workload,all,hpa,netpol,sa -n podinfo-kro"

# Demo #2
pe "clear && echo \"Demo #2 - Platform Infra Standardization (Redis) with Kro\""
pe "code images/demo-2-redis-in-cluster-0.png"
pe "code podinfo-with-redis/gen-man-by-dev-podinfo-minimal-setup.yaml"
cp podinfo-with-redis/gen-man-by-dev-podinfo-redis.yaml apps/gen-man-by-dev-podinfo.yaml
pe "echo \"GitOps Deployment - Demo 2\""
./scripts/sync_argocd_apps.sh demo-2 >/dev/null 2>&1
pe "kubectl get workload,all,hpa,netpol,sa -n podinfo-kro"
pe "echo \"What about Redis outside of the cluster, hosted by a Cloud Provider for example?\""
pe "code images/demo-2-redis-in-gcp-0.png"
pe "code -g kro/workload.yaml:421"
pe "code podinfo-with-redis/gen-man-by-dev-podinfo-minimal-setup-gcp.yaml"

# Demo #3
pe "clear && echo \"Demo #3 - Extend Abstraction with Flexibility with Kro & Score\""
pe "echo \"What are our opportunities from here?\""
pe "echo \"What is Score?\""
pe "code images/score-intro.png"
pe "code images/demo-3-kro-with-score.png"
pe "code podinfo-with-redis/score-minimal.yaml"
pe "code score-k8s/kro-workload-patch-template.tpl"
score-k8s init \
    --no-sample \
    --no-default-provisioners \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-k8s/namespace-pss-restricted.tpl \
    --patch-templates ./score-k8s/kro-workload-patch-template.tpl \
    --provisioners ./score-k8s/kro-provisioners.yaml >/dev/null 2>&1
pe "score-k8s generate podinfo/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:6.9.2 \
    --namespace podinfo-score \
    --generate-namespace \
    --output apps/gen-by-score-podinfo.yaml"
pe "echo \"GitOps Deployment - Demo 3\""
./scripts/sync_argocd_apps.sh demo-3 >/dev/null 2>&1
pe "kubectl get workload,all,hpa,netpol,sa -n podinfo-score"

# Demo #4
pe "clear && echo \"Demo #4 - Bridging Inner and Outer Loops - Score with Docker Compose\""
pe "code images/demo-4-score-docker-compose.png"
pe "code podinfo-with-redis/score-minimal.yaml"
score-compose init \
    --no-sample \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-compose/unprivileged.tpl \
	--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/horizontal-pod-autoscaler/score-compose/10-hpa.provisioners.yaml >/dev/null 2>&1
pe "score-compose generate podinfo-with-redis/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:6.9.2 \
pe "docker compose up --build -d --wait"

pe "clear && echo \"Thank You!! Cloud_Native Rejekts <3\""
