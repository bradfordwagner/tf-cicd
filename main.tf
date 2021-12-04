# setup k8s providers
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}
provider "kubectl" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "ns" {
  for_each = toset(values(var.namespaces))
  metadata {
    name = each.value
  }
}

resource "null_resource" "workflows" {
  depends_on = [kubernetes_namespace.ns]
  provisioner "local-exec" {
    command = "kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml"
  }
}

resource "null_resource" "events" {
  depends_on = [kubernetes_namespace.ns]
  provisioner "local-exec" {
    command = "kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml"
  }
  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml"
  }
}

resource "null_resource" "events_bus" {
  depends_on = [null_resource.events]
  provisioner "local-exec" {
    command = "kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml"
  }
  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml"
  }
}

# await creation of argo workflows
resource "null_resource" "await_workflows" {
  depends_on = [null_resource.workflows]
  provisioner "local-exec" {
    command = "kubectl rollout status -n argo deployment argo-server"
  }
}

resource "kubernetes_secret" "github" {
  depends_on = [null_resource.await_workflows]
  metadata {
    name = "github-access-token"
    namespace = var.namespaces.events
  }
  data = {
    token = var.github_access_token
  }
}

resource "kubernetes_secret" "quay" {
  depends_on = [null_resource.await_workflows]
  metadata {
    name = "bradfordwagner-kaniko-test-pull-secret"
    namespace = var.namespaces.workflows
  }
  data = {
    ".dockerconfigjson" = base64decode(var.quay_token)
  }
}

# setup
# 1 - secrets - ie kaniko etc
# 2 - workflows
# 3 - events
# 4 - test build

resource "helm_release" "workflows" {
  depends_on       = [kubernetes_secret.quay]
  chart            = "/Users/bwagner/workspace/github/bradfordwagner/github.bradfordwagner.chart.argocd.workflows"
  name             = "workflows"
  namespace        = var.namespaces.workflows
  create_namespace = true
  cleanup_on_fail  = true
  force_update     = true
}

resource "helm_release" "events" {
  depends_on       = [kubernetes_secret.github]
  chart            = "/Users/bwagner/workspace/github/bradfordwagner/github.bradfordwagner.argo.events.webhook"
  name             = "workflows"
  namespace        = var.namespaces.events
  create_namespace = true
  cleanup_on_fail  = true
  force_update     = true
}
