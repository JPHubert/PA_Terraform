terraform {
    backend "azurerm" {
        resource_group_name     = "msdn-tfstate-rg"
        storage_account_name    = "msdn-tfstatesa2524"
        container_name          = "terraformstate"
        key                     = "msdn.terraform.tfstate"
        access_key              = ""
    }
}
