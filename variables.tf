variable "namespaces" {
  default = {
    events    = "argo-events",
    workflows = "argo",
    vault     = "vault",
  }
}

variable "github_access_token" {
  type = string
}

variable "quay_token" {
  type = string
}
