# login to acr
registry=bradfordwagner0.azurecr.io
username="00000000-0000-0000-0000-000000000000"
password=$(az acr login --name ${registry} --expose-token --output tsv --query accessToken)
helm registry login ${registry} \
  --username ${username} \
  --password ${password}
argocd repo add ${registry} \
  --upsert \
  --type helm \
  --name bradfordwagner \
  --enable-oci \
  --username ${username} \
  --password ${password}
