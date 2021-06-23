output "target_subnetwork_mappings" {
    value = local.target_subnetwork_mappings
}

output "restricted_folder_id_subnetworks" {
    value = local.distinct_target_folder_id_subnetworks
}

output "restricted_project_id_subnetworks" {
    value = local.distinct_target_project_id_subnetworks
}

output "project_shared_vpc_restrict_subnetworks"{
    value = google_project_organization_policy.project_shared_vpc_restrict_subnetworks
}

output "folder_shared_vpc_restrict_subnetworks"{
    value = google_folder_organization_policy.folder_shared_vpc_restrict_subnetworks
}