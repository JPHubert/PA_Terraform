terraform {
    backend "azurerm" {
        resource_group_name     = "msdn-tfstate-rg"
        storage_account_name    = "msdn-tfstatesa2524"
        container_name          = "terraformstate"
        key                     = "test.terraform.tfstate"
        access_key              = ""
    }
}
