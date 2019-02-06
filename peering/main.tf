#########################################################################################################
######################################## Provider #######################################################
#########################################################################################################

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id     = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id     = "${var.tenant_id}"
}

#########################################################################################################
###################################### Data Sources #####################################################
#########################################################################################################

data "azurerm_resource_group" "transit" {
  name = "${var.name_prefix}transit${var.name_sufix}"
}

data "azurerm_resource_group" "spoke1" {
  name = "${var.name_prefix}spoke1"
}

data "azurerm_resource_group" "spoke2" {
  name = "${var.name_prefix}spoke2"
}

data "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name = "${var.name_prefix}transit${var.name_sufix}"
}

data "azurerm_virtual_network" "spoke1" {
  name                = "${var.name_prefix}_vnetspoke1${var.name_sufix}"
  resource_group_name = "${var.name_prefix}spoke1"
}

data "azurerm_virtual_network" "spoke2" {
  name                = "${var.name_prefix}_vnetspoke2${var.name_sufix}"
  resource_group_name = "${var.name_prefix}spoke2"
}

#########################################################################################################
######################################## Variables ######################################################
#########################################################################################################

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

#Naming Prefix for Azure Deployment
variable "name_prefix" {
  type    = "string"
  default = "forest"
 }

#Naming Sufix for Azure Deployment
 variable "name_sufix" {
  type    = "string"
  default = "001"
 }

#########################################################################################################
######################################## Resources ######################################################
#########################################################################################################

# VNET Peerings #
resource "azurerm_virtual_network_peering" "tran_2_spoke1" {
  name                      = "tran_2_spoke1"
  resource_group_name       = "${data.azurerm_resource_group.transit.name}"
  virtual_network_name      = "${data.azurerm_virtual_network.vnet.name}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.spoke1.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = ["data.azurerm_virtual_network.vnet",
                "data.azurerm_virtual_network.spoke1",
                "data.azurerm_virtual_network.spoke2"]
}

resource "azurerm_virtual_network_peering" "tran_2_spoke2" {
  name                      = "tran_2_spoke2"
  resource_group_name       = "${data.azurerm_resource_group.transit.name}"
  virtual_network_name      = "${data.azurerm_virtual_network.vnet.name}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.spoke2.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = ["data.azurerm_virtual_network.vnet",
                "data.azurerm_virtual_network.spoke1",
                "data.azurerm_virtual_network.spoke2"]
}

resource "azurerm_virtual_network_peering" "spoke1_2_tran" {
  name                      = "spoke1_2_tran"
  resource_group_name       = "${data.azurerm_resource_group.spoke1.name}"
  virtual_network_name      = "${data.azurerm_virtual_network.spoke1.name}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = ["azurerm_virtual_network_peering.tran_2_spoke1",
                "data.azurerm_virtual_network.vnet",
                "data.azurerm_virtual_network.spoke1",
                "data.azurerm_virtual_network.spoke2"]
}

resource "azurerm_virtual_network_peering" "spoke2_2_tran" {
  name                      = "spoke2_2_tran"
  resource_group_name       = "${data.azurerm_resource_group.spoke2.name}"
  virtual_network_name      = "${data.azurerm_virtual_network.spoke2.name}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = ["azurerm_virtual_network_peering.tran_2_spoke2",
                "data.azurerm_virtual_network.vnet",
                "data.azurerm_virtual_network.spoke1",
                "data.azurerm_virtual_network.spoke2",]
}