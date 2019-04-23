# Prow

Prow is a CI system that offers various features such as rich Github automation,
and running tests in Jenkins or on a Kubernetes cluster. You can read more about
Prow in [upstream docs][0].

## project setup

We use prow for github hooks integration.
Read about the requirements for the bot rights on your repo : 

https://github.com/kubernetes/test-infra/tree/master/prow#prow

### AKS cluster

Setup an AKS cluster with HTTP-routing enabled.
- create a `.secrets` folder at the root of the repo
    - generate the secrets (`.secrets/hmac-token` and `.secrets/cookie.txt`). -> `make generate-secrets`
    - add the github bot oauth token used by tide for decrypting the events : `.secrets/oauth-token`
    - add the github bot authentication secrets for deck : `.secrets/github-secret` 
- `make prow-prereq` will setup the prow crds, setup the cert-manager and issuer for SSL endpoint, and add the secrets to the cluster
- `make prow-config` adds the config maps and plugins

Before deploying the services, make sure to set the cluster's public ip address DNS name in the MC_* resource group, and that the ingress' host properties are aligned with it. then :
- `make prow-services` adds the prow services.

Set your github's project hook to `https://<PROW_URL>/hook` and send it all events. A green tick should come up.


### Troubleshoot 

```
kubectl get pods
k get pods
NAME                    READY   STATUS    RESTARTS   AGE
deck-85ccfb7749-9gjp2   1/1     Running   0          19m
hook-6c468b8d4b-9xqht   1/1     Running   0          19h
tide-65b756f66-wcfhd    1/1     Running   0          167m
```

Check the logs for `tide` and `hook`

```
kubectl logs hook-6c468b8d4b-9xqht
kubectl logs tide-65b756f66-wcfhd
```

Access the deck at https://<PROW_URL>

### Add a repo to tide integration

1. Give the bot `Contributor Write` access to the repo
2. Add `https://<PROW_URL>/hook` as a hook to your repo (need the secret `hmac-token` from keyvault)
3. Add your repo to `config.yaml` and `plugin.yaml`
4. `make prow-config-update`