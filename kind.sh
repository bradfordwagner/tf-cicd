#!/usr/bin/env zsh
# inputs: create|delete
# used to create/destroy kind clusters
# puts kube contexts into ~/.kube/ or ~/.kube/kind/internal
# internal signifies in cluster access

function create_admin_cluster() {
  cluster_name=$1
  argocd=30001
  vault=30003
  kind create cluster --kubeconfig ~/.kube/${cluster_name} --config /dev/stdin <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
networking:
  apiServerPort: 30100
  apiServerAddress: 0.0.0.0
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    # to check this configuration: kubectl -n kube-system get configmap kubeadm-config -oyaml
    kind: ClusterConfiguration
    apiServer:
      certSANs:
        - 0.0.0.0
        - bwagner-studio
        - localhost
  extraPortMappings:
  - containerPort: ${vault}
    hostPort: ${vault}
    protocol: TCP
  - containerPort: ${argocd}
    hostPort: ${argocd}
    protocol: TCP
  image: kindest/node:v1.28.0
EOF
}

function create_cluster() {
  cluster_name=${1}
  create_${cluster_name}_cluster ${cluster_name}
  kind get kubeconfig --internal --name ${cluster_name} > ~/.kube/kind/internal/${cluster_name}
  export KUBECONFIG=~/.kube/kind/internal/${cluster_name}
  kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode \
    > ${KUBECONFIG}_ca
  kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}' \
    > ${KUBECONFIG}_server
}

function delete_cluster() {
  cluster_name=${1}
  kind delete clusters ${cluster_name}
  rm \
    ~/.kube/${cluster_name} \
    ~/.kube/kind/internal/${cluster_name}
}

function create_dirs() {
  mkdir -p ~/.kube/kind/internal
}

# main
action=${1}
create_dirs
${action}_cluster admin
