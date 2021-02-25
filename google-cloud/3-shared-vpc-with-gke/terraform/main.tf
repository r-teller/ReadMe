
module "project_standup" {
    source = "./modules/1_environment_standup"

    for_each = var.environments
    environment = each.key
    org_id = var.organization_id
    billing_account = var.billing_account

    host_project    = each.value.host_project
    enabled_apis    = each.value.enabled_apis
    primary_network = each.value.primary_network
    pods_subnetwork = each.value.pods_subnetwork
    svcs_subnetwork = each.value.svcs_subnetwork
}

module "service_project_attach" {    
    source = "./modules/2_service_project_attach"
    for_each = var.environments
    
    project_type        = each.value.host_project != null ? "service" : "host"
    host_project_id     = try(module.project_standup[each.value.host_project].project_id,null)
    service_project_id  = module.project_standup[each.key].project_id
}

module "jump_host" {
    source = "./modules/3_jump_host"
    for_each = var.environments
    
    environment = each.key
    vpc_name    = try(module.project_standup[each.value.host_project].network_self_link,
        module.project_standup[each.key].network_self_link)
    project_id  = module.project_standup[each.key].project_id
    random_id   = module.project_standup[each.key].id
    subnetwork  = try(module.project_standup[each.value.host_project].subnetwork_self_link,
        module.project_standup[each.key].subnetwork_self_link)
    region      = module.project_standup[each.key].region    
}

module "gke_cluster" {
    source = "./modules/4_gke_cluster"
    for_each = var.environments

    environment = each.key
    vpc_name    = try(module.project_standup[each.value.host_project].network_self_link,
        module.project_standup[each.key].network_self_link)
    project_id  = module.project_standup[each.key].project_id
    random_id   = module.project_standup[each.key].id
    subnetwork  = try(module.project_standup[each.value.host_project].subnetwork_self_link,
        module.project_standup[each.key].subnetwork_self_link)
    region =  module.project_standup[each.key].region       
    gke_master_net = each.value.gke_master_net
}