#########################################################################################################
########################################   Locals  ######################################################
#########################################################################################################


locals {
    pa_count        =   "2"
    subnet_mgmt     =   "${cidrsubnet("${var.tran_vnet_address}", 8, 0)}"
    subnet_untrust  =   "${cidrsubnet("${var.tran_vnet_address}", 8, 1)}"
    subnet_trust    =   "${cidrsubnet("${var.tran_vnet_address}", 8, 2)}"
    subnet_shared   =   "${cidrsubnet("${var.tran_vnet_address}", 8, 3)}"
    subnet_egress   =   "${cidrsubnet("${var.tran_vnet_address}", 8, 4)}"
    subnet_dmz      =   "${cidrsubnet("${var.tran_vnet_address}", 8, 5)}"
    pa_mgt_int      =   "${cidrhost(local.subnet_mgmt, 4)}"
    pa_untrust_int  =   "${cidrhost(local.subnet_untrust, 4)}"
    pa_trust_int    =   "${cidrhost(local.subnet_trust, 4)}"
    pa_dmz_int      =   "${cidrhost(local.subnet_dmz, 4)}"
    egress_lb_addy  =   "${cidrhost(local.subnet_egress, 100)}"
    dmz_lb_addy     =   "${cidrhost(local.subnet_dmz, 100)}"
}