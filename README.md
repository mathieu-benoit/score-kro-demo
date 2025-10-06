# score-kro-demo

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mathieu-benoit/score-kro-demo)

Prepare local cluster:
```bash
./scripts/setup-kind-cluster.sh

kubectl apply -f kro/workload.yaml
```

Score:
```bash
score-k8s init \
    --no-default-provisioners \
    --patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-k8s/namespace-pss-restricted.tpl \
    --patch-templates ./score-k8s/kro-workload-patch-template.tpl

score-k8s generate podinfo/score.yaml \
    --image ghcr.io/stefanprodan/podinfo:latest \
    --namespace podinfo \
    --generate-namespace \
    --output apps/podinfo.yaml
```

Deployment:
```bash
# Optional, without GitOps:
kubectl apply -f apps/podinfo.yaml

# Otherwise, with GitOps:
git push
```


## Demo 0:

IDEA: showing limits of Kro, and how Score can help. But also showing if it the right way to go.

![Demo 0](images/demo-0.png)


```bash
cp podinfo/kro-cr-podinfo.yaml apps/kro-cr-podinfo.yaml
```

But what about Day-2? Provide a v2 of RGD?

Change from:

```yaml
    - id: appNamespace
      template:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: ${schema.spec.namespace}
          # labels:
          #   pod-security.kubernetes.io/enforce: "restricted"
          #   pod-security.kubernetes.io/audit: "baseline"
          #   pod-security.kubernetes.io/warn: "baseline"
```
To:

```yaml

    - id: appNamespace
      template:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: ${schema.spec.namespace}
          labels:
            pod-security.kubernetes.io/enforce: "restricted"
            pod-security.kubernetes.io/audit: "baseline"
            pod-security.kubernetes.io/warn: "baseline"
```

This is an easy change, but what about more complex changes?
Not even created by the platform engineers, but by developers like rename the resources in the podinfo app?
Will create a second app and dont clean up the first one.

Limits:     - CEL, ARGS/Lists [], Depends on Operator - No Dry Run.... -> create role and rolebinding based on an input list of subjects (list, objects)

Decision:

KRO limitations → Should we address them with Score, or use other tools?

New limitations: Out of 10 engineers, maybe only 2 are aware of the added complexity.
But with Score you can define behavior directly, without relying on an operator.

See next Demo 1.

## Demo 1:

- Diagram
- Commands
- Output/Learnings

## Else

- KRO limitations:
    - CEL
    - Iterate over Objects, etc. --> https://github.com/kubernetes-sigs/kro/issues/17
    - DAY 2 Operation, Error Handling
    - Depends on Operator - No Dry Run

    - Use Same CR, but rename name, namespace -> Create a new application and don`t clean up the old one

