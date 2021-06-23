locals {
    targets_path = "./targets"
    
    targets_sets = fileset(local.targets_path,"*")
    target_mappings = flatten([ for targets in local.targets_sets: [
            jsondecode(file("${local.targets_path}/${targets}"))
        ]
    ])
}

module "restricted_subnetworks" {
    source = "../../modules/restricted_subnetworks"
    
    target_mappings = local.target_mappings
    host_project_id = var.host_project_id
}