# Demos

In the following demos, we gradually increase complexity to explore:

* Why abstraction tools like KRO can be challenging for many teams,
* What their limits are, and
* How to overcome these limits—or even remove unnecessary layers—by choosing the right tools for your platform and team.

TOC:
- [Setup](#setup)
- Kro
  - [Demo #1 - FIXME]()
  - [Demo #1 - FIXME]()
- Score
  - [Demo #3 - FIXME]()
  - [Demo #4 - Score and Docker Compose](#demo-4---score---docker-compose)

## Setup

Prepare a local Kubernetes cluster:

```bash
./scripts/setup-kind-cluster.sh
./scripts/setup-argocd.sh
```

Apply a sample KRO ResourceGraphDefinition (RGD) and Custom Resource manually:

```bash
kubectl apply -f kro/workload.yaml
kubectl apply -f apps/kro-cr-podinfo.yaml
```

## Demo #1 - Kro - FIXME

FIXME

![Demo 0](../images/demo-0.png)

![Demo 1](../images/demo-1.png)

1. The **Platform Team** defines a ResourceGraphDefinition (RGD) `workload` including best practices like resource limits, probes, security context, and pod disruption budgets.
2. **KRO** validates the `workload` definition and allows creation of `Workload` CustomResources (CR) from the RGD.
3. The **Developer** creates a new `Workload` CR defining app-specific values such as name, image, replicas, ports, and environment variables.
4. **Argo CD** watches a Git repository folder and deploys the new `Workload` CR to the cluster.
5. The **KRO Operator** observes these `Workload` CRs and generates all required Kubernetes resources defined in the RGD.

We simulate this by copying an example CR from the `podinfo` demo:

```bash
cp podinfo/gen-man-by-dev-podinfo.yaml apps/gen-man-by-dev-podinfo.yaml
```

## Demo #2 - Kro - FIXME

FIXME

## Demo #3 - Score - FIXME

To improve it, we introduced [Score](https://score.dev/) — adding another layer on top of KRO to generate `Workload` CRs dynamically using Go templating.

So, while KRO looks static, Score adds dynamic flexibility through templating. The created RDG is like you execute `helm template` and get the final manifest.

![Demo 2](../images/demo-2.png)

```bash
score-k8s init \
    --no-sample \
    --no-default-provisioners \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-k8s/namespace-pss-restricted.tpl \
    --patch-templates ./score-k8s/kro-workload-patch-template.tpl \
    --provisioners ./score-k8s/kro-provisioners.yaml

score-k8s generate podinfo/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:latest \
    --namespace podinfo \
    --generate-namespace \
    --override-property containers.podinfo.variables.PODINFO_UI_MESSAGE="Hello, from ArgoCD, Kro and Score!" \
    --output apps/gen-by-score-podinfo.yaml
```

```bash
# Option 1 – Manual deployment (without GitOps)
kubectl apply -f apps/gen-by-score-podinfo.yaml

# Option 2 – GitOps workflow
git push
```

## Demo #4 - Score - Docker Compose

```bash
score-compose init \
    --no-sample \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-compose/unprivileged.tpl

score-compose generate podinfo/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:latest \
    --override-property containers.podinfo.variables.PODINFO_UI_MESSAGE="Hello, from Compose and Score!"

docker compose up --build -d
```