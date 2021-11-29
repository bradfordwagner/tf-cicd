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
