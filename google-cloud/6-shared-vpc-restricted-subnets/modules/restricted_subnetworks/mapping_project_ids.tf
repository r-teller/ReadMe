locals {    
    unpack_target_project_ids = flatten([
        for target in local.concat_target_subnetwork_mappings: [
            for project_id in target.project_ids: {
                id          = project_id
                subnetwork  = target.subnetwork
            }
        ]
    ])
    distinct_target_project_ids = distinct([for target in local.unpack_target_project_ids: target["id"]])
    merge_target_project_ids = merge(
        [
            for key in local.distinct_target_project_ids:
                  {for x in local.unpack_target_project_ids:
                     key => x["subnetwork"]... if x["id"] == key
                  }  
        ]...
    )
    distinct_target_project_id_subnetworks = {
        for k,v in local.merge_target_project_ids: k => flatten(distinct(v))
    }
}