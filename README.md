# score-kro-demo

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mathieu-benoit/score-kro-demo)

## TODOs

First:
- [x] DevContainer with Docker, Kind, Score pre-installed
- [x] Kind cluster setup in [`scripts/setup-kind-cluster.sh`](scripts/setup-kind-cluster.sh)
- [ ] Install Kro
- [ ] Define Workload (no cloud provider to start)
- [ ] Score file and patchers
- [ ] In-cluster provisioners

--> Objective: be able to deploy `podinfo` via Score and Kro, with env vars.

```bash
score-k8s init ...

score-k8s generate podinfo/score.yaml

./scripts/setup-kind-cluster.sh

kubectl apply -f manifests.yaml
```

Second:
- [ ] Find a more complex sample apps: OnlineBoutique (with Redis)?
- [ ] Get this sample apps working with Kro via Score

Later:
- [ ] GKE
- [ ] CI/CD
- [ ] GCP-KCC
- [ ] Argo