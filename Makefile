# Disable all the default make stuff
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

## Display a list of the documented make targets
.PHONY: help
help:
	@echo Documented Make targets:
	@perl -e 'undef $$/; while (<>) { while ($$_ =~ /## (.*?)(?:\n# .*)*\n.PHONY:\s+(\S+).*/mg) { printf "\033[36m%-30s\033[0m %s\n", $$2, $$1 } }' $(MAKEFILE_LIST) | sort

.PHONY: .FORCE
.FORCE:

## Create a local Kind cluster.
.PHONY: kind-create-cluster
kind-create-cluster:
	./scripts/setup-kind-cluster.sh

## Install kro/workload.yaml to Kubernetes.
.PHONY: install-kro-workload
install-kro-workload:
	kubectl apply -f kro/workload.yaml
	kubectl wait resourcegraphdefinition workload \
		--for condition=Ready \
		--timeout=90s

## Deploy simple/score.yaml to Kubernetes.
.PHONY: deploy-simple
deploy-simple: install-kro-workload
	score-k8s init \
    	--no-sample \
    	--no-default-provisioners \
    	--patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-k8s/namespace-pss-restricted.tpl \
    	--patch-templates ./score-k8s/kro-workload-patch-template.tpl
	score-k8s generate simple/score.yaml \
		--image ghcr.io/mathieu-benoit/my-sample-workload:latest \
		--namespace simple \
		--generate-namespace
	kubectl apply -f manifests.yaml

## Test Kubernetes resources after simple/score.yaml has been deployed.
.PHONY: test-simple
test-simple: deploy-simple
	kubectl wait workload simple \
		-n simple \
		--for condition=InstanceSynced \
		--timeout=90s
	kubectl wait deployments/simple \
		-n simple \
		--for condition=Available \
		--timeout=90s
	kubectl wait pods \
		-n simple \
		-l app.kubernetes.io/name=simple \
		--for condition=Ready \
		--timeout=90s
	kubectl get workload,all,sa,httproute -n simple

## Deploy podinfo/score.yaml to Kubernetes.
.PHONY: deploy-podinfo
deploy-podinfo: install-kro-workload
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
    	--override-property containers.podinfo.variables.PODINFO_UI_MESSAGE="Hello, from Kro and Score!"
	kubectl apply -f manifests.yaml

## Test Kubernetes resources after podinfo/score.yaml has been deployed.
.PHONY: test-podinfo
test-podinfo: deploy-podinfo
	kubectl wait workload podinfo \
		-n podinfo \
		--for condition=InstanceSynced \
		--timeout=90s
	kubectl wait deployments/podinfo \
		-n podinfo \
		--for condition=Available \
		--timeout=90s
	kubectl wait pods \
		-n podinfo \
		-l app.kubernetes.io/name=podinfo \
		--for condition=Ready \
		--timeout=90s
	kubectl get workload,all,sa,httproute -n podinfo
