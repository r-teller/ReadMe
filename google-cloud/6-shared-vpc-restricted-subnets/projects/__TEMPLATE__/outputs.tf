## Uncomment output snippet below to troubleshoot when subnetworks either do/do not show up when expected
# output "target_subnetwork_mappings" {
#     value = module.restrict_subnetworks.*.target_subnetwork_mappings
# }

output "restricted_folder_id_subnetworks" {
    value = module.restricted_subnetworks.*.restricted_folder_id_subnetworks
}
output "restricted_project_id_subnetworks" {
    value = module.restricted_subnetworks.*.restricted_project_id_subnetworks
}