# inputs: create|delete
# used to create/destroy kind clusters
# puts kube contexts into ~/.kube/kind/ or ~/.kube/kind/internal
# internal signifies in cluster access

function create_admin_cluster() {
  cluster_name=$1
  argocd=30001
  kind create cluster --kubeconfig ~/.kube/kind/${cluster_name} --config /dev/stdin <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
nodes:
- role: control-plane
  extraPortMappings:
  # argocd
  - containerPort: ${argocd}
    hostPort: ${argocd}
    protocol: TCP
- role: worker
- role: worker
- role: worker
EOF
}

function create_cicd_cluster() {
  cluster_name=$1
  github_webhook=30000
  argo_workflows=30002
  kind create cluster --kubeconfig ~/.kube/kind/${cluster_name} --config /dev/stdin <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
nodes:
- role: control-plane
  extraPortMappings:
  # github webhook
  - containerPort: ${github_webhook}
    hostPort: ${github_webhook}
    protocol: TCP
  # argo workflows
  - containerPort: ${argo_workflows}
    hostPort: ${argo_workflows}
    protocol: TCP
- role: worker
- role: worker
- role: worker
EOF
}

function create_cluster() {
  cluster_name=${1}
  create_${cluster_name}_cluster ${cluster_name}
  kind get kubeconfig --internal --name ${cluster_name} > ~/.kube/kind/internal/${cluster_name}
}

function delete_cluster() {
  cluster_name=${1}
  kind delete clusters ${cluster_name}
  rm \
    ~/.kube/kind/${cluster_name} \
    ~/.kube/kind/internal/${cluster_name}
}

function create_dirs() {
  mkdir -p ~/.kube/kind/internal
}

# main
action=${1}
create_dirs
${action}_cluster admin
${action}_cluster cicd

