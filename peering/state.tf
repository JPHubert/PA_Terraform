terraform {
    backend "azurerm" {
        resource_group_name     = "secdevops"
        storage_account_name    = "secdevopssa"
        container_name          = "terraformstate"
        key                     = "peering.terraform.tfstate"
        access_key              = ""
    }
}
