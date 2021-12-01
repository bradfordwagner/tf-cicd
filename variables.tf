variable "region" {
  type    = string
  default = "eastus2"
}

variable "namespaces" {
  default = {
    events    = "argo-events",
    workflows = "argo",
  }
}

variable "github_access_token" {
  type = string
}

variable "quay_token" {
  type = string
}
