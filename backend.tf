terraform {
  backend "azurerm" {
    subscription_id      = "fd0b0519-e1f7-4fe7-af09-86f1e796c5b2"
    resource_group_name  = "storage-rg"
    storage_account_name = "tfstate25484"
    container_name       = "tfstate"
    key                  = "tf-cicd"
  }
}

