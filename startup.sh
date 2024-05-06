#!/usr/bin/env zsh
# use a local cluster like minikube to bootstrap a target cluster
# the end state might be local cluster only
export KUBECONFIG=~/.kube/admin
ns=argocd
set -x
kubectl apply -n ${ns} -k https://github.com/bradfordwagner/deploy-argocd.git/ &>/dev/null

echo awaiting argocd server + redis to startup
kubectl wait -n ${ns} deploy/argocd-server --for condition=available --timeout=5m
kubectl wait -n ${ns} deploy/argocd-redis  --for condition=available --timeout=5m

echo port forwarding argocd server
port_forward=8080
kubectl port-forward -n ${ns} deploy/argocd-server ${port_forward}:8080 &
sleep 3

# setup new password for argocd
initial_password=$(kubectl -n ${ns} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 \
  --username admin \
  --password ${initial_password} \
  --insecure
argocd account update-password \
  --account admin \
  --current-password ${initial_password} \
  --new-password admin1234

# setup secrets for cluster bootstrap
kubectl create secret generic login    -n ${ns} --from-literal="username=admin" --from-literal="password=admin1234"
kubectl create secret generic contexts -n ${ns} \
  --from-file ~/.kube/kind/internal/admin

sleep 5
# setup argo workflows
kubectl apply -f argocd/apps/argo_workflows/appset.yaml
kubectl wait -n ${ns} application/argo-workflows-in-cluster --for jsonpath={.status.health.status}=Healthy --timeout=5m

# this will switch to a workflow
argo submit ./workflows/init_clusters.yaml --watch

unset KUBECONFIG # remove hard coded admin ctx
pkill kubectl    # stop the port forward
