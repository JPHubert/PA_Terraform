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
  name = "${var.name_prefix}transit"
}

data "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
}

data "azurerm_subnet" "subnet_mgmt" {
  name                 = "mgmt"
  virtual_network_name = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name  = "${data.azurerm_resource_group.transit.name}"
}

data "azurerm_subnet" "subnet_untrust" {
  name                 = "untrust"
  virtual_network_name = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name  = "${data.azurerm_resource_group.transit.name}"
}

data "azurerm_subnet" "subnet_trust" {
  name                 = "trust"
  virtual_network_name = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name  = "${data.azurerm_resource_group.transit.name}"
}

data "azurerm_subnet" "subnet_egress" {
  name                 = "egress"
  virtual_network_name = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name  = "${data.azurerm_resource_group.transit.name}"
}

data "azurerm_subnet" "subnet_dmz" {
  name                 = "dmz"
  virtual_network_name = "${var.name_prefix}_vnet${var.name_sufix}"
  resource_group_name  = "${data.azurerm_resource_group.transit.name}"
}

#########################################################################################################
######################################## Variables ######################################################
#########################################################################################################

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

#Username for PA FW
variable "username" {
  type    = "string"
  default = "cloudadmin"
}

#Password for PA FW
variable "password" {
  type    = "string"
  default = "p@l0alt0"
}

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

#Azure Region/Location
variable "region" {
  type    = "string"
  default = "east us"
}

#Azure VNET
variable "tran_vnet_address" {
    type    = "string"
}

#Azure VM size for VM-Series
variable "pa_firewall_size" {
  type    = "map"
  default = {
    "small"   = "Standard_DS3_v2"
    "medium"  = "Standard_DS4_v2"
    "large"   = "Standard_DS5_v2"
  }
 }

#########################################################################################################
######################################## Resources ######################################################
#########################################################################################################

#Azure IaaS Public IP Addresses
resource "azurerm_public_ip" "pamgtpip" {
  count = "${local.pa_count}"
  name                = "${var.name_prefix}_00${count.index + 1}_mgmtpip"
  location            = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  sku                 = "Standard"
  public_ip_address_allocation = "Static"
  domain_name_label   = "pamgt00${count.index + 1}${element(random_string.ingressid.*.result, count.index)}"
}
resource "azurerm_public_ip" "pauntrustpip" {
  count = "${local.pa_count}"
  name                = "${var.name_prefix}_00${count.index + 1}_untrustpip"
  location            = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  sku                 = "Standard"
  public_ip_address_allocation = "Static"
  domain_name_label   = "pauntrust${count.index}${element(random_string.ingressid.*.result, count.index)}"
}

# Azure LB Public IP Addresses "
resource "random_string" "ingressid" {
  count = "${local.pa_count}"
  length = 12
  special = false
  lower = true
  upper = false
}
resource "azurerm_public_ip" "ingresspip" {
  name                = "${var.name_prefix}_ingress_lbfw${var.name_sufix}"
  location            = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  sku                 = "Standard"
  public_ip_address_allocation = "Static"
  domain_name_label   = "lbfw${var.name_sufix}${random_string.ingressid.0.result}"
}

# Azure Load Balancers #
resource "azurerm_lb" "egresslb" {
  name                = "${var.name_prefix}_egress_lb${var.name_sufix}"
  location            = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  sku                 = "standard"
  
  frontend_ip_configuration {
    name                = "${var.name_prefix}_egress${var.name_sufix}_frontend"
    private_ip_address  = "${local.egress_lb_addy}"
    private_ip_address_allocation = "static"
    subnet_id           = "${data.azurerm_subnet.subnet_egress.id}"
  }
  frontend_ip_configuration {
    name                = "${var.name_prefix}_dmz${var.name_sufix}_frontend"
    private_ip_address  = "${local.dmz_lb_addy}"
    private_ip_address_allocation = "static"
    subnet_id           = "${data.azurerm_subnet.subnet_dmz.id}"
  }
}
resource "azurerm_lb_backend_address_pool" "egresslb_be_pool" {
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.egresslb.id}"
  name = "${var.name_prefix}_egress_bepool${var.name_sufix}"
}
resource "azurerm_lb_backend_address_pool" "egresslb_dmzbe_pool" {
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.egresslb.id}"
  name = "${var.name_prefix}_egress_dmzbepool${var.name_sufix}"
}
resource "azurerm_lb_probe" "egress_lbprobe" {
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.egresslb.id}"
  name = "TCP-22"
  port = 22
}
resource "azurerm_lb_rule" "egress_haports_lbrule" {
  name = "${var.name_prefix}_${var.name_sufix}_haports"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.egresslb.id}"
  protocol = "ALL"
  frontend_ip_configuration_name = "${azurerm_lb.egresslb.frontend_ip_configuration.0.name}"
  frontend_port = 0
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.egresslb_be_pool.id}"
  backend_port = 0
  probe_id = "${azurerm_lb_probe.egress_lbprobe.id}"
  load_distribution = "SourceIP"
}
resource "azurerm_lb_rule" "egress_dmzhaports_lbrule" {
  name = "${var.name_prefix}_${var.name_sufix}_dmzhaports"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.egresslb.id}"
  protocol = "ALL"
  frontend_ip_configuration_name = "${azurerm_lb.egresslb.frontend_ip_configuration.1.name}"
  frontend_port = 0
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.egresslb_dmzbe_pool.id}"
  backend_port = 0
  probe_id = "${azurerm_lb_probe.egress_lbprobe.id}"
  load_distribution = "SourceIP"
}

resource "azurerm_lb" "ingresslb" {
  name                = "${var.name_prefix}_ingress_lb${var.name_sufix}"
  location            = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  sku                 = "standard"
  
  frontend_ip_configuration {
    name                = "${var.name_prefix}_ingress_lb${var.name_sufix}_frontend"
    public_ip_address_id = "${azurerm_public_ip.ingresspip.id}"
  }
}
resource "azurerm_lb_backend_address_pool" "ingresslb_be_pool" {
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.ingresslb.id}"
  name = "${var.name_prefix}_ingress_bepool${var.name_sufix}"
}
resource "azurerm_lb_probe" "ingress_lbprobe" {
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  loadbalancer_id = "${azurerm_lb.ingresslb.id}"
  name = "TCP-22"
  port = 22
}

# Palo Alto NGFW vNICs
resource "azurerm_network_interface" "vnic_mgt" {
  count = "${local.pa_count}"
  name = "${var.name_prefix}_fw00${count.index + 1}_vnic_mgt"
  location = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"

  ip_configuration {
    name = "ipconfig_mgt"
    subnet_id = "${data.azurerm_subnet.subnet_mgmt.id}"
    private_ip_address = "${cidrhost(local.subnet_mgmt, (4 + count.index))}"
    private_ip_address_allocation = "Static"
    public_ip_address_id = "${element(azurerm_public_ip.pamgtpip.*.id, count.index)}"
  }
}

resource "azurerm_network_interface" "vnic_untrust" {
  count = "${local.pa_count}"
  name = "${var.name_prefix}_fw00${count.index + 1}_vnic_untrust"
  location = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  enable_ip_forwarding = true
 
  ip_configuration {
    name = "ipconfig_untrust"
    subnet_id = "${data.azurerm_subnet.subnet_untrust.id}"
    private_ip_address = "${cidrhost(local.subnet_untrust, (4 + count.index))}"
    private_ip_address_allocation = "Static"
    public_ip_address_id = "${element(azurerm_public_ip.pauntrustpip.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.ingresslb_be_pool.id}"]
  }
}

resource "azurerm_network_interface" "vnic_trust" {
  count = "${local.pa_count}"
  name = "${var.name_prefix}_fw00${count.index + 1}_vnic_trust"
  location = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name = "ipconfig_trust"
    subnet_id = "${data.azurerm_subnet.subnet_trust.id}"
    private_ip_address = "${cidrhost(local.subnet_trust, (4 + count.index))}"
    private_ip_address_allocation = "Static"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.egresslb_be_pool.id}"]
  }
}

resource "azurerm_network_interface" "vnic_dmz" {
  count = "${local.pa_count}"
  name = "${var.name_prefix}_fw00${count.index + 1}_vnic_dmz"
  location = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name = "ipconfig_dmz"
    subnet_id = "${data.azurerm_subnet.subnet_dmz.id}"
    private_ip_address = "${cidrhost(local.subnet_dmz, (4 + count.index))}"
    private_ip_address_allocation = "Static"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.egresslb_dmzbe_pool.id}"]
  }
}

# Azure FW Availablity Set
resource "azurerm_availability_set" "pafwas" {
  name = "${var.name_prefix}as${var.name_sufix}"
  location = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  managed = "true"
}

# Palo Alto NGFW VM
resource "azurerm_virtual_machine" "pafw" {
  count = "${local.pa_count}"
  name     = "${var.name_prefix}fw00${count.index + 1}"
  location = "${data.azurerm_resource_group.transit.location}"
  resource_group_name = "${data.azurerm_resource_group.transit.name}"
  vm_size = "${var.pa_firewall_size["small"]}"
  availability_set_id = "${azurerm_availability_set.pafwas.id}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  primary_network_interface_id = "${element(azurerm_network_interface.vnic_mgt.*.id, count.index)}"
  network_interface_ids = ["${element(azurerm_network_interface.vnic_mgt.*.id, count.index)}",
                          "${element(azurerm_network_interface.vnic_untrust.*.id, count.index)}",
                          "${element(azurerm_network_interface.vnic_trust.*.id, count.index)}",
                          "${element(azurerm_network_interface.vnic_dmz.*.id, count.index)}"]

  plan {
    name = "bundle1"
    publisher = "paloaltonetworks"
    product = "vmseries1"
  }

  storage_image_reference {
    publisher = "paloaltonetworks"
    offer = "vmseries1"
    sku = "bundle1"
    version = "latest"
  }  

  storage_os_disk {
    name = "${var.name_prefix}fw00${count.index + 1}_osdisk"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "${var.name_prefix}fw00${count.index + 1}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }



  os_profile_linux_config {
    disable_password_authentication = false
  }
}

#########################################################################################################
########################################   Output  ######################################################
#########################################################################################################

output pa_mgt_fqdn {
  value = "${azurerm_public_ip.pamgtpip.*.fqdn}"
}

#########################################################################################################
########################################  Modules  ######################################################
#########################################################################################################

// modules panos_1 {
//   source = "/modules/panos"
//   pa = "${azurerm_public_ip.pamgtpip.0.fqdn}"
// }

// modules panos_2 {
//   source = "/modules/panos"
//   pa = "${azurerm_public_ip.pamgtpip.1.fqdn}"
// }