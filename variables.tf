variable "namespaces" {
  default = {
    events    = "argo-events",
    workflows = "argo",
    vault     = "vault",
  }
}

variable "vault_storage_key" {
  type = string
}

variable "vault_sp_secret" {
  type = string
}

variable "github_access_token" {
  type = string
}

variable "role_id" {
  type = string
}

variable "secret_id" {
  type = string
}

