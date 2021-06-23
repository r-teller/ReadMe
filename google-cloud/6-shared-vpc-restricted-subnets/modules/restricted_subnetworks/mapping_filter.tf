locals {    
    ## Parses output from subnetworks_list module to create map of subnets and add additional flags for future filtering
    ### Filters can be one or more of the following Subnetwork, Region and Network. All filters are treated as AND
    target_subnetwork_mappings = flatten([
        for target in var.target_mappings: [
            for subnetwork in module.subnetworks_list.subnetworks: {
                folder_ids          = target.folder_ids
                project_ids         = target.project_ids

                subnetwork          = subnetwork.subnetwork
                subnetwork_filter   = can(target.subnet_match.subnetwork) ? length(regexall(target.subnet_match.subnetwork.regex, subnetwork.selfLink)) >0 ? "true" : "false" : "na"
                subnetwork_regex    = can(target.subnet_match.subnetwork) ? target.subnet_match.subnetwork.regex : "na"

                region              = subnetwork.region
                region_filter       = can(target.subnet_match.region) ? length(regexall(target.subnet_match.region.regex, subnetwork.region)) >0 ? "true" : "false" : "na"
                region_regex        = can(target.subnet_match.region) ? target.subnet_match.region.regex : "na"

                network             = subnetwork.network
                network_filter      = can(target.subnet_match.network) ? length(regexall(target.subnet_match.network.regex, subnetwork.network)) >0 ? "true" : "false" : "na"
                network_regex       = can(target.subnet_match.network) ? target.subnet_match.network.regex : "na"
            }
        ]
    ])
    
    ## Parses output from subnetworks_list module to filter out subnets that do not match the regex specified in the target JSON file
    filter_target_subnetwork_mappings = [
        for target in local.target_subnetwork_mappings: {
            folder_ids  = target.folder_ids
            project_ids = target.project_ids
            subnetwork  = target.subnetwork
        } if target.subnetwork_filter != "false" && target.region_filter != "false" && target.network_filter != "false"
    ]

    additional_target_subnetwork_mappings = flatten([
        for target in var.target_mappings: [
            for subnet in target.subnet_list: {
                folder_ids  = target.folder_ids
                project_ids = target.project_ids
                subnetwork  = subnet
            }
        ]
    ])

    concat_target_subnetwork_mappings = concat(local.filter_target_subnetwork_mappings, local.additional_target_subnetwork_mappings)
}