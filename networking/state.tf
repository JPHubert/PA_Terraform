terraform {
    backend "azurerm" {
        resource_group_name     = "secdevops"
        storage_account_name    = "secdevopssa"
        container_name          = "terraformstate"
        key                     = "networking.terraform.tfstate"
        access_key              = "PrqyeRGephtbjP0kIQ044va9PRwHoLgMoNNKgWMZcfrWPSpch9uxCtn/rtQPwiCNeeSJ+a2E6wJ4Tm5Xn/UsbA=="
    }
}