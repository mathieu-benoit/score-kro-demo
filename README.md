# score-kro-demo

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mathieu-benoit/score-kro-demo)

## TODOs

First:
- [x] DevContainer with Docker, Kind, Score pre-installed
- [x] Kind cluster setup in [`scripts/setup-kind-cluster.sh`](scripts/setup-kind-cluster.sh)
- [ ] TODO-Install Kro --> Artem
- [ ] TODO-Define the Workload `ResourceGraphDefinition` (no cloud provider to start) --> Artem
- [ ] TODO-Score file and patchers --> Mathieu
- [ ] TODO-In-cluster provisioners --> Mathieu

--> Objective: be able to deploy `podinfo` via Score and Kro, with env vars.

Rough script for the "first demo":
```bash
score-k8s init ...

score-k8s generate podinfo/score.yaml --image ghcr.io/stefanprodan/podinfo:latest

./scripts/setup-kind-cluster.sh

kubectl apply -f manifests.yaml
```

Second:
- [ ] Find a more complex sample apps: OnlineBoutique (with Redis)?
- [ ] Get this sample apps working with Kro via Score
- [ ] With in-cluster Redis at this stage?

Later:
- [ ] GKE
- [ ] CI/CD
- [ ] GCP-KCC
- [ ] Argo