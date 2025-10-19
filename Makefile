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

## Deploy simple/score.yaml to Kubernetes.
.PHONY: deploy-simple
deploy-simple:
	score-k8s init \
    	--no-sample \
    	--no-default-provisioners
	score-k8s generate simple/score.yaml \
		--image ghcr.io/mathieu-benoit/my-sample-workload:latest \
		--namespace simple \
		--generate-namespace
	kubectl apply -f manifests.yaml

## Test Kubernetes resources after simple/score.yaml has been deployed.
.PHONY: deploy-simple
test-simple: deploy-simple
	sleep 5
	kubectl wait deployments/simple \
		-n simple \
		--for condition=Available \
		--timeout=90s
	kubectl wait pods \
		-n simple \
		-l app.kubernetes.io/name=simple \
		--for condition=Ready \
		--timeout=90s
	kubectl get workload,all,httproute -n simple
