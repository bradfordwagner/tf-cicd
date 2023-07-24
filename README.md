# tf-cicd

## ArgoCD
```bash

# for the overly lazy
./kind.sh create; tf init; tf apply -auto-approve; ./startup.sh

# delete the clusters
./kind.sh delete

# bootstrap all of our apps
kubectl apply -f argocd/bootstrap

# set your kube config to minikube
# pbpaste will place the address into your clipboard
# enter it into your browser to see argocd
# user/pass = admin:admin1234
./startup.sh

```

## Rotate Secrets
```bash
# vault k8s auth approle
role=k8s_auth_bootstrapper
ROLE_ID=$(vault read auth/approle/role/${role}/role-id -format=json | jq '.data.role_id' -r)
SECRET_ID=$(vault write auth/approle/role/${role}/secret-id -format=json | jq '.data.secret_id' -r)
echo ROLE_ID=${ROLE_ID}
echo SECRET_ID=${SECRET_ID}
```
