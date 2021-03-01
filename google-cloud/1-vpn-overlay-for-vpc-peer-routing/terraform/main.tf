data "google_client_config" "clent_config" {
}

data "http" "http_cloudresourcemanager_googleapis_com" {
  url   = "https://cloudresourcemanager.googleapis.com/v1beta1/organizations"
  request_headers = {
    accept          =  "application/json"
    authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
  }
}

data "google_organization" "organization" {
    count           = var.organization_id != null ? 1 : 0
    organization    = var.organization_id
}

data "google_folder" "folder" {
    count   = var.folder_id != null ? 1 : 0
    folder  = var.folder_id
}

data "google_project" "project" {
    count       = var.project_id != null ? 1 : 0
    project_id  = var.project_id
}

data "google_billing_account" "billing_account" {
    count           = var.billing_account != null ? 1 : 0
    billing_account = var.billing_account    
}

locals {
    http_organizations_json = try(jsondecode(data.http.http_cloudresourcemanager_googleapis_com.body).organizations,[])
    pre_flight_check = (
        (length(distinct([var.project_id,var.organization_id,var.folder_id])) > 1 || length(local.http_organizations_json) < 1) && 
        ((var.project_id == null && var.billing_account != null) || var.project_id != null)
    )
    pre_flight_status = {
        0: {
            description: "Current pre-flight status check"
            status: local.pre_flight_check
        }
        1: {
            description: "If your account has access to at least one organization you must specify one following variables: project_id, organization_id or folder-id"
            status: (length(distinct([var.project_id,var.organization_id,var.folder_id])) > 1 || length(local.http_organizations_json) < 1)
            var_names: ["project_id","organization_id","folder_id"]
        },
        2: {
            var_names: ["billing_account"]
            description: "Billing account must be specified when projects are created, not required for projects already created",
            status: ((var.project_id == null && var.billing_account != null) || var.project_id != null)
        }
        3: {
            description: "Organization Count"
            status: length(local.http_organizations_json)
        }
    }
    vpc_peer_mappings = zipmap(keys(var.environments),[
        for environment in keys(var.environments):[
            for peer in var.environments[environment].vpc_peers: {
                name="${environment}-to-${peer}"
                local=module.environment_standup[environment].network.self_link
                remote=module.environment_standup[peer].network.self_link
            } if local.pre_flight_check
        ]
    ])
    vpn_peerings = flatten([
        for vpn_peers in var.vpn_peerings: {          
            first = {
                name = vpn_peers.first,
                network = module.environment_standup[vpn_peers.first].network.self_link,
                project_id = module.environment_standup[vpn_peers.first].project_id,
                region =  module.environment_standup[vpn_peers.first].region,
                advertised_networks = {"10.0.0.0/8"="RFC-1918","172.16.0.0/12"="RFC-1918","192.168.0.0/16"="RFC-1918"},
            },
            second = {
                name = vpn_peers.second,
                network = module.environment_standup[vpn_peers.second].network.self_link,
                project_id = module.environment_standup[vpn_peers.second].project_id,
                region =  module.environment_standup[vpn_peers.second].region,
                advertised_networks = {(var.environments[vpn_peers.second].gke_master_net)="GKE Master Network"}
            }
        } if local.pre_flight_check
    ])
}

output "pre_flight_status" {
    value = local.pre_flight_status
}

output "environment_standup" {
    value = local.pre_flight_check ? [for x in module.environment_standup: {
        deployment_target: var.project_id != null ? "Existing Project" :  var.folder_id != null ? "Existing Folder" : "Existing Organization"
        environment: x.environment
        organization_id: var.organization_id != null ? var.organization_id : "Undefined",
        project_id: var.project_id != null ? var.project_id : x.project_id,
        folder_id: var.folder_id != null ? var.folder_id : "Undefined",
        vpc_name: x.network.id
    }]: [{ error: "You must specify at least one of the following variables or environment_standup will fail, project_id, organization_id, folder_id"}]
}

module "environment_standup" {
    source = "./modules/1_environment_standup"

    for_each = local.pre_flight_check ? var.environments : {}
    environment = each.key

    org_id = try(var.organization_id,null)
    folder_id = try(var.folder_id,null)
    project_id = try(var.project_id,null)

    billing_account = var.billing_account

    primary_network = each.value.primary_network
    pods_subnetwork = each.value.pods_subnetwork
    svcs_subnetwork = each.value.svcs_subnetwork
}

module "vpc_peering" {
    source = "./modules/2_vpc_peering"
    for_each = local.pre_flight_check ? local.vpc_peer_mappings : {}
    peerings = each.value
}

module "jump_host" {
    source = "./modules/3_jump_host"
    for_each = local.pre_flight_check ? var.environments : {}
    
    environment = each.key
    vpc_name = module.environment_standup[each.key].network.self_link
    project_id = module.environment_standup[each.key].project_id
    random_id = module.environment_standup[each.key].id
    subnetwork = module.environment_standup[each.key].subnetwork
    region =  module.environment_standup[each.key].region    
}

module "gke_cluster" {
    source = "./modules/4_gke_cluster"
    for_each = local.pre_flight_check ? var.environments : {}

    environment = each.key
    vpc_name = module.environment_standup[each.key].network.self_link
    project_id = module.environment_standup[each.key].project_id
    random_id = module.environment_standup[each.key].id
    subnetwork = module.environment_standup[each.key].subnetwork
    gke_master_net = each.value.gke_master_net
    region =  module.environment_standup[each.key].region       
}

module "vpn_peering" {
    source = "./modules/5_vpn_peering"

    for_each = local.pre_flight_check ? { for peering in local.vpn_peerings: "${peering.first.name}-to-${peering.second.name}" => peering} : {}
    networks = each.value
}