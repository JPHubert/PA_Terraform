#########################################################################################################
######################################## Provider #######################################################
#########################################################################################################

provider "panos" {
    hostname = "${var.pa}"
    username = "${var.username}"
    password = "${var.password}"
}

#########################################################################################################
######################################## Resources ######################################################
#########################################################################################################

#FQDN for PA FW
variable "pa" {
  type    = "string"
}

#########################################################################################################
######################################## Variables ######################################################
#########################################################################################################

variable "tran_vnet_address" {
    type = "string"
}

#Username for PA FW
variable "username" {
  type    = "string"
  default = "cloudadmin"
}

#Password for PA FW
variable "password" {
  type    = "string"
  default = "!Azure123##"
}

# PA Settings
resource "panos_general_settings" "settings" {
    dns_primary = "168.63.129.16"
    ntp_primary_address = "time.windows.com"
    ntp_primary_auth_type = "none"
    timezone = "US/Central"
}

# PA Management Interface Profile
resource "panos_management_profile" "mgmt_profile" {
    name = "Allow Monitoring"
    ping = true
    ssh = true
}

# PA Ethernet Interfaces
resource "panos_ethernet_interface" "eth1" {
    name = "ethernet1/1"
    comment = "External/Untrust Interface"
    management_profile = "${panos_management_profile.mgmt_profile.name}"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
    create_dhcp_default_route = true
}

resource "panos_ethernet_interface" "eth2" {
    name = "ethernet1/2"
    comment = "Internal/Trust Interface"
    management_profile = "${panos_management_profile.mgmt_profile.name}"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
}

resource "panos_ethernet_interface" "eth3" {
    name = "ethernet1/3"
    comment = "DMZ Interface"
    management_profile = "${panos_management_profile.mgmt_profile.name}"
    vsys = "vsys1"
    mode = "layer3"
    enable_dhcp = true
}

# PA Zones
resource "panos_zone" "untrust" {
    name = "Untrust"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.eth1.name}"]
    enable_user_id = false
}

resource "panos_zone" "trust" {
    name = "Trust"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.eth2.name}"]
    enable_user_id = true
}

resource "panos_zone" "dmz" {
    name = "DMZ"
    mode = "layer3"
    interfaces = ["${panos_ethernet_interface.eth3.name}"]
    enable_user_id = true
}

# PA Virtual Routers
resource "panos_virtual_router" "vr-untrust" {
    name = "Untrust VR"
    static_dist = 15
    interfaces = ["${panos_ethernet_interface.eth1.name}"]
}

resource "panos_virtual_router" "vr-trust" {
    name = "Trust VR"
    static_dist = 15
    interfaces = ["${panos_ethernet_interface.eth2.name}"]
}

resource "panos_virtual_router" "vr-dmz" {
    name = "DMZ VR"
    static_dist = 15
    interfaces = ["${panos_ethernet_interface.eth3.name}"]
}

# PA VR Static Routes
# VR-Untrust
resource "panos_static_route_ipv4" "azure_default_untrust" {
    name = "Default_Internet"
    virtual_router = "${panos_virtual_router.vr-untrust.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth1.name}"
    destination = "0.0.0.0/0"
    next_hop = "${cidrhost(local.subnet_untrust, 1)}"
}

resource "panos_static_route_ipv4" "azure_hp_untrust" {
    name = "Azure_HealthProbe"
    virtual_router = "${panos_virtual_router.vr-untrust.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth1.name}"
    destination = "168.63.129.16/32"
    next_hop = "${cidrhost(local.subnet_untrust, 1)}"
}


resource "panos_static_route_ipv4" "azure_local_untrust" {
    name = "Azure_Local"
    virtual_router = "${panos_virtual_router.vr-untrust.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth1.name}"
    destination = "${local.subnet_untrust}"
    next_hop = "${cidrhost(local.subnet_untrust, 1)}"
}

resource "panos_static_route_ipv4" "azure_untrust_dmz" {
    name = "Azure_DMZ"
    virtual_router = "${panos_virtual_router.vr-untrust.name}"
    type = "next-vr"
    destination = "${local.subnet_dmz}"
    next_hop = "${panos_virtual_router.vr-dmz.name}"
}

resource "panos_static_route_ipv4" "azure_untrust_trust" {
    name = "Azure_Trust"
    virtual_router = "${panos_virtual_router.vr-untrust.name}"
    type = "next-vr"
    destination = "${local.subnet_trust}"
    next_hop = "${panos_virtual_router.vr-trust.name}"
}

#resource "panos_static_route_ipv4" "azure_untrust_spoke1" {
#   name = "Azure_Spoke1"
#    virtual_router = "${panos_virtual_router.vr-untrust.name}"
#    type = "next-vr"
#    destination = "${local.subnet_spoke1}"
#    next_hop = "${panos_virtual_router.vr-trust.name}"
#}

#resource "panos_static_route_ipv4" "azure_untrust_spoke2" {
#    name = "Azure_Spoke2"
#    virtual_router = "${panos_virtual_router.vr-untrust.name}"
#    type = "next-vr"
#    destination = "${local.subnet_spoke2}"
#    next_hop = "${panos_virtual_router.vr-trust.name}"
#}

# PA VR Static Routes
# VR-Trust
resource "panos_static_route_ipv4" "azure_default_trust" {
    name = "Default_Internet"
    virtual_router = "${panos_virtual_router.vr-trust.name}"
    type = "next-vr"
    destination = "0.0.0.0/0"
    next_hop = "${panos_virtual_router.vr-untrust.name}"
}

resource "panos_static_route_ipv4" "azure_hp_trust" {
    name = "Azure_HealthProbe"
    virtual_router = "${panos_virtual_router.vr-trust.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth2.name}"
    destination = "168.63.129.16/32"
    next_hop = "${cidrhost(local.subnet_trust, 1)}"
}

resource "panos_static_route_ipv4" "azure_local_trust" {
    name = "Azure_Local"
    virtual_router = "${panos_virtual_router.vr-trust.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth2.name}"
    destination = "${local.subnet_trust}"
    next_hop = "${cidrhost(local.subnet_trust, 1)}"
}

resource "panos_static_route_ipv4" "azure_trust_untrust" {
    name = "Azure_Untrust"
    virtual_router = "${panos_virtual_router.vr-trust.name}"
    type = "next-vr"
    destination = "${local.subnet_untrust}"
    next_hop = "${panos_virtual_router.vr-untrust.name}"
}

#resource "panos_static_route_ipv4" "azure_trust_egress" {
#    name = "Azure_Egress"
#    virtual_router = "${panos_virtual_router.vr-trust.name}"
#    type = "ip-address"
#    interface = "${panos_ethernet_interface.eth2.name}"
#    destination = "${local.subnet_egress}"
#    next_hop = "${cidrhost(local.subnet_trust, 1)}"
#}

resource "panos_static_route_ipv4" "azure_trust_dmz" {
    name = "Azure_DMZ"
    virtual_router = "${panos_virtual_router.vr-trust.name}"
    type = "next-vr"
    destination = "${local.subnet_dmz}"
    next_hop = "${panos_virtual_router.vr-untrust.name}"
}

#resource "panos_static_route_ipv4" "azure_trust_spoke1" {
#    name = "Azure_Spoke1"
#    virtual_router = "${panos_virtual_router.vr-trust.name}"
#    type = "ip-address"
#    interface = "${panos_ethernet_interface.eth2.name}"
#    destination = "${local.subnet_spoke1}"
#    next_hop = "${cidrhost(local.subnet_trust, 1)}"
#}

#resource "panos_static_route_ipv4" "azure_trust_spoke2" {
#    name = "Azure_Spoke2"
#    virtual_router = "${panos_virtual_router.vr-trust.name}"
#    type = "ip-address"
#    interface = "${panos_ethernet_interface.eth2.name}"
#    destination = "${local.subnet_spoke2}"
#    next_hop = "${cidrhost(local.subnet_trust, 1)}"
#}

# PA VR Static Routes
# VR-DMZ
resource "panos_static_route_ipv4" "azure_default_dmz" {
    name = "Default_Internet"
    virtual_router = "${panos_virtual_router.vr-dmz.name}"
    type = "next-vr"
    destination = "0.0.0.0/0"
    next_hop = "${panos_virtual_router.vr-untrust.name}"
}

resource "panos_static_route_ipv4" "azure_hp_dmz" {
    name = "Azure_HealthProbe"
    virtual_router = "${panos_virtual_router.vr-dmz.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth3.name}"
    destination = "168.63.129.16/32"
    next_hop = "${cidrhost(local.subnet_dmz, 1)}"
}

resource "panos_static_route_ipv4" "azure_local_dmz" {
    name = "Azure_Local"
    virtual_router = "${panos_virtual_router.vr-dmz.name}"
    type = "ip-address"
    interface = "${panos_ethernet_interface.eth3.name}"
    destination = "${local.subnet_dmz}"
    next_hop = "${cidrhost(local.subnet_dmz, 1)}"
}

#resource "panos_static_route_ipv4" "azure_dmz_spoke1" {
#    name = "Azure_Spoke1"
#    virtual_router = "${panos_virtual_router.vr-dmz.name}"
#    type = "next-vr"
#    destination = "${local.subnet_spoke1}"
#    next_hop = "${panos_virtual_router.vr-untrust.name}"
#}

#resource "panos_static_route_ipv4" "azure_dmz_spoke2" {
#    name = "Azure_Spoke2"
#    virtual_router = "${panos_virtual_router.vr-dmz.name}"
#    type = "next-vr"
#    destination = "${local.subnet_spoke2}"
#    next_hop = "${panos_virtual_router.vr-untrust.name}"
#}

#PA FQDN Address Object
resource "panos_address_object" "azurefqdn" {
    name = "inbound_elb_fqdn"
    type = "fqdn"
    value = "azuremadeup.fqdn.com"
    description = "Example FQDN ADObject for dNAT"
}

#PA NATs
resource "panos_nat_rule" "outbound" {
    name = "Internet_Outbound"
    description = "Internet Outbound SNAT"
    source_zones = ["${panos_zone.trust.name}", "${panos_zone.dmz.name}"]
    destination_zone = "${panos_zone.untrust.name}"
    source_addresses = ["any"]
    destination_addresses = ["any"]
    sat_type = "dynamic-ip-and-port"
    sat_interface = "${panos_ethernet_interface.eth1.name}"
    sat_address_type = "interface-address"
}

resource "panos_nat_rule" "inbound" {
    name = "ELB_Inbound"
    description = "Internet Inbound DNAT/SNAT"
    source_zones = ["${panos_zone.untrust.name}"]
    destination_zone = "${panos_zone.untrust.name}"
    source_addresses = ["any"]
    destination_addresses = ["${panos_address_object.azurefqdn.name}"]
    sat_type = "dynamic-ip-and-port"
    sat_interface = "${panos_ethernet_interface.eth2.name}"
    sat_address_type = "interface-address"
    dat_type = "dynamic"
    dat_address = "10.10.10.10"
    dat_port = "80"
}

#PA Security Policies
resource "panos_security_policy" "pa_sp_rules" {
    rule {
        name = "Trust_HealthProbe"
        source_zones = ["${panos_zone.trust.name}"]
        source_addresses = ["168.63.129.16/32"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["${panos_zone.trust.name}"]
        destination_addresses = ["any"]
        applications = ["ssh"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
    rule {
        name = "Untrust_HealthProbe"
        source_zones = ["${panos_zone.untrust.name}"]
        source_addresses = ["168.63.129.16/32"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["${panos_zone.untrust.name}"]
        destination_addresses = ["any"]
        applications = ["ssh"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
    rule {
        name = "DMZ_HealthProbe"
        source_zones = ["${panos_zone.dmz.name}"]
        source_addresses = ["168.63.129.16/32"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["${panos_zone.dmz.name}"]
        destination_addresses = ["any"]
        applications = ["ssh"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
    rule {
        name = "Internet_Allow"
        source_zones = ["${panos_zone.trust.name}"]
        source_addresses = ["any"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["${panos_zone.untrust.name}"]
        destination_addresses = ["any"]
        applications = ["any"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
    rule {
        name = "Inbound_Allow"
        source_zones = ["${panos_zone.untrust.name}"]
        source_addresses = ["any"]
        source_users = ["any"]
        hip_profiles = ["any"]
        destination_zones = ["${panos_zone.trust.name}"]
        destination_addresses = ["${panos_address_object.azurefqdn.name}"]
        applications = ["web-browsing"]
        services = ["application-default"]
        categories = ["any"]
        action = "allow"
    }
}

    