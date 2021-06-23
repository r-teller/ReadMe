data "google_client_config" "clent_config" {
}

data "http" "http_getSubnetworks" {
    url   = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/aggregated/subnetworks?alt=json"
    request_headers = {
        accept          = "application/json"
        authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
    }
}

locals {
    http_getSubnetworks = jsondecode(data.http.http_getSubnetworks.body)
    subnetworks = flatten([for region in keys(local.http_getSubnetworks.items): [
            for subnetwork in local.http_getSubnetworks.items[region].subnetworks: {
                name        = subnetwork.name
                selfLink    = subnetwork.selfLink
                subnetwork  = regex("projects/.+",subnetwork.selfLink)
                network     = element(split("/", subnetwork.network), length(split("/", subnetwork.network))-1)
                region      = element(split("/", subnetwork.region), length(split("/", subnetwork.region))-1)
                purpose     = subnetwork.purpose
                ipCidrRange = subnetwork.ipCidrRange
            }
        ] if contains(keys(local.http_getSubnetworks.items[region]), "subnetworks")
    ])
}