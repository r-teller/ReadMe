variable "billing_account" {
    type = string
    default = null
}

variable "organization_id" {
    type = number
    default = null
}

variable "project_id" {
    type = string
    default = null
}

variable "folder_id" {
    type = number
    default = null
}
variable "vpn_peerings" {
    default = []
    type = list(object({
        first=string,
        second=string
    }))
}
variable "environments" {
    type = map(object({
            gke_master_net  = string
            primary_network = string
            pods_subnetwork = string
            svcs_subnetwork = string
            vpc_peers = list(string)

    }))
}