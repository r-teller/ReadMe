locals {
    vpc_peer_mappings = zipmap(keys(var.environments),[
        for environment in keys(var.environments):[
            for peer in var.environments[environment].vpc_peers: {
                name="${environment}-to-${peer}"
                local=module.project_standup[environment].network_self_link
                remote=module.project_standup[peer].network_self_link
            }
        ]
    ])
    vpn_peerings = flatten([
        for vpn_peers in var.vpn_peerings: {          
            first = {
                name = vpn_peers.first,
                network = module.project_standup[vpn_peers.first].network_self_link,
                project_id = module.project_standup[vpn_peers.first].project_id,
                region =  module.project_standup[vpn_peers.first].region,
                advertised_networks = {"10.0.0.0/8"="RFC-1918","172.16.0.0/12"="RFC-1918","192.168.0.0/16"="RFC-1918"},
            },
            second = {
                name = vpn_peers.second,
                network = module.project_standup[vpn_peers.second].network_self_link,
                project_id = module.project_standup[vpn_peers.second].project_id,
                region =  module.project_standup[vpn_peers.second].region,
                advertised_networks = {(var.environments[vpn_peers.second].gke_master_net)="GKE Master Network"}
            }
        }
    ])
}


module "environment_standup" {
    source = "./modules/1_environment_standup"

    for_each = var.environments
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
    for_each = local.vpc_peer_mappings
    peerings = each.value
}

module "jump_host" {
    source = "./modules/3_jump_host"
    for_each = var.environments
    
    environment = each.key
    vpc_name = module.project_standup[each.key].network_self_link
    project_id = module.project_standup[each.key].project_id
    random_id = module.project_standup[each.key].id
    subnetwork = module.project_standup[each.key].subnetwork_self_link
    region =  module.project_standup[each.key].region    
}

module "gke_cluster" {
    source = "./modules/4_gke_cluster"
    for_each = var.environments

    environment = each.key
    vpc_name = module.project_standup[each.key].network_self_link
    project_id = module.project_standup[each.key].project_id
    random_id = module.project_standup[each.key].id
    subnetwork = module.project_standup[each.key].subnetwork_self_link
    gke_master_net = each.value.gke_master_net
    region =  module.project_standup[each.key].region       
}

module "vpn_peering" {
    source = "./modules/5_vpn_peering"

    for_each = { for peering in local.vpn_peerings: "${peering.first.name}-to-${peering.second.name}" => peering}
    networks = each.value
}