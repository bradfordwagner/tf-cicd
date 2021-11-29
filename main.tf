# setup k8s providers
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "example" {
  for_each = toset(values(var.namespaces))
  metadata {
    name = each.value
  }
}
