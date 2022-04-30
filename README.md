# tf-cicd

## ArgoCD
```bash

# for the overly lazy
./kind.sh create; tf init; tf apply -auto-approve; ./startup.sh

# bootstrap all of our apps
kubectl apply -f argocd/bootstrap

# get the context for new cluster
az aks get-credentials --resource-group bradfordwagner-infra --name infra --admin --overwrite-existing -f ~/.kube/cicd
az aks list | jq '.[] | "\(.name) \(.resourceGroup)"' -r | xargs -n2 zsh -c 'az aks get-credentials --resource-group $2 --name $1 --admin -f ~/.kube/cicd --overwrite-existing' zsh

# create namespaces and secrets required for events+workflows
clear; tf init
clear; tf apply   -auto-approve

# set your kube config to minikube
# pbpaste will place the address into your clipboard
# enter it into your browser to see argocd
# user/pass = admin:admin1234
./startup.sh

# take the webhook ip address and put it into clipboard
k get svc --kubeconfig ~/.kube/personal -n argo-events github-webhook -o json | jq -r '.status.loadBalancer.ingress[0].ip' | pbcopy

```
