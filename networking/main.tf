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
######################################## Variables ######################################################
#########################################################################################################

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

#Naming Prefix for Azure Deployment
variable "name_prefix" {
  type    = "string"
  default = "AZEUS"
 }

#Naming Sufix for Azure Deployment
 variable "name_sufix" {
  type    = "string"
  default = "001"
 }

 #Azure Region/Location
variable "region" {
  type    = "string"
  default = "east us"
}

variable "tran_vnet_address" {
    type    = "string"
}

variable "spoke1_vnet_address" {
    type    = "string"
}

variable "spoke2_vnet_address" {
    type    = "string"
}

#########################################################################################################
######################################## Resources ######################################################
#########################################################################################################

# Resouce Groups #
resource "azurerm_resource_group" "transit" {
  name     = "${var.name_prefix}transit"
  location = "${var.region}"
}

resource "azurerm_resource_group" "spoke1" {
  name     = "${var.name_prefix}Spoke1"
  location = "${var.region}"
}

resource "azurerm_resource_group" "spoke2" {
  name     = "${var.name_prefix}Spoke2"
  location = "${var.region}"
}

# Network Security Group #
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name_prefix}_nsg_${var.name_sufix}"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"

    security_rule {
    name                       = "AllowAll-IN"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "AllowAll-OUT"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Transit Route Tables #
resource "azurerm_route_table" "mgmt_rt001" {
  name                = "${var.name_prefix}_mgmt_rt001"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"
  
  route {
    name              = "route_default"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "Internet"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_mgmt}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_untrust"
    address_prefix    = "${local.subnet_untrust}"
    next_hop_type     = "None"
  }
  route {
    name              = "route_trust"
    address_prefix    = "${local.subnet_trust}"
    next_hop_type     = "None"
  }
  route {
    name              = "route_shared"
    address_prefix    = "${local.subnet_shared}"
    next_hop_type     = "None"
  }
    route {
    name              = "route_egress"
    address_prefix    = "${local.subnet_egress}"
    next_hop_type     = "None"
  }
  route {
    name              = "route_dmz"
    address_prefix    = "${local.subnet_dmz}"
    next_hop_type     = "None"
  }
}

resource "azurerm_route_table" "trust_rt001" {
  name                = "${var.name_prefix}_trust_rt001"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"
  
  route {
    name              = "route_default"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_egress"
    address_prefix    = "${local.subnet_egress}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_trust}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_shared"
    address_prefix    = "${local.subnet_shared}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_untrust"
    address_prefix    = "${local.subnet_untrust}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_dmz"
    address_prefix    = "${local.subnet_dmz}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
    route {
    name              = "route_mgmt"
    address_prefix    = "${local.subnet_mgmt}"
    next_hop_type     = "None"
  }
}

resource "azurerm_route_table" "shared_rt001" {
  name                = "${var.name_prefix}_shared_rt001"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"
  
  route {
    name              = "route_default"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_shared}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_trust"
    address_prefix    = "${local.subnet_trust}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_untrust"
    address_prefix    = "${local.subnet_untrust}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_dmz"
    address_prefix    = "${local.subnet_dmz}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
    route {
    name              = "route_mgmt"
    address_prefix    = "${local.subnet_mgmt}"
    next_hop_type     = "None"
  }
}

resource "azurerm_route_table" "untrust_rt001" {
  name                = "${var.name_prefix}_untrust_rt001"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"

  route {
    name              = "route_default"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "Internet"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_untrust}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_trust"
    address_prefix    = "${local.subnet_trust}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.pa_untrust_int}"
  }
  route {
    name              = "route_dmz"
    address_prefix    = "${local.subnet_dmz}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.pa_untrust_int}"
  }
  route {
    name              = "route_mgmt"
    address_prefix    = "${local.subnet_mgmt}"
    next_hop_type     = "None"
  }
  route {
    name              = "route_shared"
    address_prefix    = "${local.subnet_shared}"
    next_hop_type     = "None"
  }
}

resource "azurerm_route_table" "dmz_rt001" {
  name                = "${var.name_prefix}_dmz_rt001"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"

  route {
    name              = "route_default"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.dmz_lb_addy}"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_dmz}"
    next_hop_type     = "VnetLocal"
  }
  route {
    name              = "route_fw"
    address_prefix    = "${var.tran_vnet_address}"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.dmz_lb_addy}"
  }
  route {
    name              = "route_mgmt"
    address_prefix    = "${local.subnet_mgmt}"
    next_hop_type     = "None"
  }
}

# Spoke Route Tables #
resource "azurerm_route_table" "spoke1_rt001" {
  name                = "${var.name_prefix}_bastion_rt001"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.spoke1.name}"
  
  route {
    name              = "route_internet"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_spoke1}"
    next_hop_type     = "VnetLocal"
  }
   route {
    name              = "route_summary"
    address_prefix    = "10.0.0.0/8"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
}

resource "azurerm_route_table" "spoke2_rt001" {
  name                = "${var.name_prefix}_bastion_rt002"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.spoke2.name}"
  
  route {
    name              = "route_internet"
    address_prefix    = "0.0.0.0/0"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
  route {
    name              = "route_local"
    address_prefix    = "${local.subnet_spoke2}"
    next_hop_type     = "VnetLocal"
  }
   route {
    name              = "route_summary"
    address_prefix    = "10.0.0.0/8"
    next_hop_type     = "VirtualAppliance"
    next_hop_in_ip_address = "${local.egress_lb_addy}"
  }
}

# Transit Virtual Network #
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}_vnet${var.name_sufix}"
  address_space       = ["${var.tran_vnet_address}"]
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.transit.name}"
}

# Transit Subnets #
resource "azurerm_subnet" "mgmt" {
  name                      = "mgmt"
  resource_group_name       = "${azurerm_resource_group.transit.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "${local.subnet_mgmt}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.mgmt_rt001.id}"
}
resource "azurerm_subnet" "untrust" {
  name                      = "untrust"
  resource_group_name       = "${azurerm_resource_group.transit.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "${local.subnet_untrust}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.untrust_rt001.id}"
}
resource "azurerm_subnet" "trust" {
  name                      = "trust"
  resource_group_name       = "${azurerm_resource_group.transit.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "${local.subnet_trust}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.trust_rt001.id}"
}
resource "azurerm_subnet" "shared" {
  name                      = "shared"
  resource_group_name       = "${azurerm_resource_group.transit.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "${local.subnet_shared}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.shared_rt001.id}"
}
resource "azurerm_subnet" "egress" {
  name                      = "egress"
  resource_group_name       = "${azurerm_resource_group.transit.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "${local.subnet_egress}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}
resource "azurerm_subnet" "dmz" {
  name                      = "dmz"
  resource_group_name       = "${azurerm_resource_group.transit.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "${local.subnet_dmz}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.dmz_rt001.id}"
}

# Spoke Virtual Networks #
resource "azurerm_virtual_network" "spoke1" {
  name                = "${var.name_prefix}_vnetspoke1${var.name_sufix}"
  address_space       = ["${var.spoke1_vnet_address}"]
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.spoke1.name}"
}

resource "azurerm_virtual_network" "spoke2" {
  name                = "${var.name_prefix}_vnetspoke2${var.name_sufix}"
  address_space       = ["${var.spoke2_vnet_address}"]
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.spoke2.name}"
}

# Spoke Subnets #
resource "azurerm_subnet" "bastion1" {
  name                      = "bastion"
  resource_group_name       = "${azurerm_resource_group.spoke1.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke1.name}"
  address_prefix            = "${local.subnet_spoke1}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.spoke1_rt001.id}"
}

resource "azurerm_subnet" "bastion2" {
  name                      = "bastion"
  resource_group_name       = "${azurerm_resource_group.spoke2.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke2.name}"
  address_prefix            = "${local.subnet_spoke2}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  route_table_id            = "${azurerm_route_table.spoke2_rt001.id}"
}
