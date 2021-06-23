locals {
    unpack_target_folder_ids = flatten([
        for target in local.concat_target_subnetwork_mappings: [
            for folder_id in target.folder_ids: {
                id          = "folders/${folder_id}"
                subnetwork  = target.subnetwork
            }
        ]
    ])
    distinct_target_folder_ids = distinct([for target in local.unpack_target_folder_ids: target["id"]])
    merge_target_folder_ids = merge(
        [
            for key in local.distinct_target_folder_ids:
                  {for x in local.unpack_target_folder_ids:
                     key => x["subnetwork"]... if x["id"] == key
                  }  
        ]...
    )
    distinct_target_folder_id_subnetworks = {
        for k,v in local.merge_target_folder_ids: k => flatten(distinct(v))
    }
}