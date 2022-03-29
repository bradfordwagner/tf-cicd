# setup k8s providers
provider "kubernetes" {
  config_path = "~/.kube/personal"
}

resource "kubernetes_namespace" "ns" {
  for_each = toset(values(var.namespaces))
  metadata {
    name = each.value
  }
}

resource "kubernetes_secret" "github" {
  depends_on = [kubernetes_namespace.ns]
  metadata {
    name = "github-access-token"
    namespace = var.namespaces.events
  }
  data = {
    token = var.github_access_token
  }
}

resource "kubernetes_secret" "quay" {
  depends_on = [kubernetes_namespace.ns]
  metadata {
    name = "bradfordwagner-kaniko-test-pull-secret"
    namespace = var.namespaces.workflows
  }
  data = {
    ".dockerconfigjson" = base64decode(var.quay_token)
  }
}

