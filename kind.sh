# inputs: create|delete
# used to create/destroy kind clusters
# puts kube contexts into ~/.kube/kind/ or ~/.kube/kind/internal
# internal signifies in cluster access

function create_cluster() {
  cluster_name=${1}
  kind create cluster --kubeconfig ~/.kube/kind/${cluster_name} --config /dev/stdin <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF
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

