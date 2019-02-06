#MSDN terraform-sp SPN

subscription_id = "663dee8a-c675-45e2-92d9-c9137c273253"
client_id = "549db045-8154-4725-907e-47f99d6d4491"
client_secret = "4792c298-896d-4c43-a037-75685c383124"
tenant_id = "7afd73dd-006e-4ab4-9cd4-59b86183823c"


#VNET Address CIDR
vnet_address = "10.64.0.0/16"
#MGMT Address Prefix x.x.0.0
mgmt_address_prefix = "(cidrsubnet("${var.vnet_address}", 8, 0))"
#Untrust Address Prefix x.x.1.0
untrust_address_prefix = "(cidrsubnet("${var.vnet_address}", 8, 1))"
#Trust Address Prefix x.x.2.0
trust_address_prefix = cidrsubnet("${var.vnet_address}", 8, 2)
#SharedServices Address Prefix x.x.3.0
shared_address_prefix = cidrsubnet("${var.vnet_address}", 8, 3)
#Egress Address Prefix x.x.4.0
egress_address_prefix = cidrsubnet("${var.vnet_address}", 8, 4)
#DMZ Address Prefix x.x.5.0
dmz_address_prefix = cidrsubnet("${var.vnet_address}", 8, 5)

