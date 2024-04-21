# tf-cicd

## Rotate Secrets
```bash
# vault k8s auth approle
role=k8s_auth_bootstrapper
ROLE_ID=$(vault read auth/approle/role/${role}/role-id -format=json | jq '.data.role_id' -r)
SECRET_ID=$(vault write auth/approle/role/${role}/secret-id -format=json | jq '.data.secret_id' -r)
echo ROLE_ID=${ROLE_ID}
echo SECRET_ID=${SECRET_ID}
```
