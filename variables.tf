variable "namespaces" {
  default = {
    events    = "argo-events",
    workflows = "argo",
  }
}

variable "vault_sp_secret" {
  type = string
}

variable "github_access_token" {
  type = string
}

variable "quay_token" {
  type = string
}
