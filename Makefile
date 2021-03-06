CLUSTER_RG="prowess"
CLUSTER_NAME="prowess"
AZP_TOKEN=$(shell cat .secrets/azp-token)

prow: prow-prereq prow-config prow-services
.PHONY: prow

prow-prereq: setup-crds setup-cert-manager prow-secrets deck-secrets
.PHONY: prow-prereq

prow-config:
	kubectl create cm config --from-file=config.yaml=config.yaml
	kubectl create cm plugins --from-file=plugins.yaml=plugins.yaml
.PHONY: prow-config

prow-config-update:
	kubectl create cm config --from-file=config.yaml=config.yaml -o yaml --dry-run | kubectl replace -f -
	kubectl create cm plugins --from-file=plugins.yaml=plugins.yaml -o yaml --dry-run | kubectl replace -f -
.PHONY: prow-config-update

prow-secrets:
	# hmac is used for encrypting Github webhook payloads.
	kubectl create secret generic hmac-token --from-file=hmac=.secrets/hmac-token
	# oauth is used for merging PRs, adding/removing labels and comments.
	kubectl create secret generic oauth-token --from-file=oauth=.secrets/oauth-token
.PHONY: prow-secrets

azp-secret:
	# oauth is used for merging PRs, adding/removing labels and comments.
	kubectl create secret generic azp --from-file=AZP_TOKEN=.secrets/azp-token
.PHONY: prow-secrets

azp_token: 
	echo $(AZP_TOKEN)
.PHONY:azp_token

start-local-agent:
	 docker run \
	 -e AZP_TOKEN=$(AZP_TOKEN) \
	 -e AZP_POOL=aks-go113 \
	 -e AZP_URL=https://dev.azure.com/project-genesys \
	 -it --rm test/azdevops-agent:docker-1.13.0
.PHONY: start-local-agent

deck-secrets:
# for the content of the github-oauth-config secret, 
# see https://github.com/kubernetes/test-infra/blob/master/prow/docs/pr_status_setup.md#how-to-setup-pr-status
	kubectl create secret generic github-oauth-config --from-file=secret=.secrets/github-secret	
	kubectl create secret generic cookie --from-file=secret=.secrets/cookie.txt
.PHONY: deck-secrets

generate-secrets:
	openssl rand -out .secrets/hmac-token -hex 20
	openssl rand -out .secrets/cookie.txt -base64 64

prow-services:
	kubectl apply -f deck.yaml
	kubectl apply -f hook.yaml
	kubectl apply -f tide.yaml
	echo "Deploying the ingress. make sure to set the cluster's public ip address DNS in the MC_* RG"
	echo "and that the ingress host properties are aligned with it."
	kubectl apply -f ingress.yaml
.PHONY: prow-services

setup-crds: 
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/test-infra/master/prow/cluster/prowjob_customresourcedefinition.yaml
.PHONY: setup-crds

setup-cert-manager: 
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/test-infra/master/prow/cluster/cert-manager.yaml
	kubectl apply -f cluster-issuer.yaml
.PHONY: setup-cert-manager

get-cluster-credentials:
	az aks get-credentials -g $(CLUSTER_RG) -n $(CLUSTER_NAME)
.PHONY: get-cluster-credentials

ensure-http-routing:
	az aks enable-addons -g $(CLUSTER_RG) -n $(CLUSTER_NAME) -a http_application_routing
.PHONY: ensure-http-routing

agent-build:
	docker build pipeline-agent -f pipeline-agent/Dockerfile -t serbrech/azdevops-agent:latest
.PHONY: agent-image

agent-push:
	docker push serbrech/azdevops-agent:latest
.PHONY: agent-image

keyvault-upload:
	az keyvault secret set --name prow-kubeconfig --vault-name genesys-dev --file .secrets/kubeconfig
	az keyvault secret set --name azdevops-azp-token --vault-name genesys-dev --file .secrets/azp-token
	az keyvault secret set --name prow-cookie --vault-name genesys-dev --file .secrets/cookie.txt
	az keyvault secret set --name prow-github-secret --vault-name genesys-dev --file .secrets/github-secret
	az keyvault secret set --name prow-hmac-token --vault-name genesys-dev --file .secrets/hmac-token
	az keyvault secret set --name prow-oauth-token --vault-name genesys-dev --file .secrets/oauth-token





