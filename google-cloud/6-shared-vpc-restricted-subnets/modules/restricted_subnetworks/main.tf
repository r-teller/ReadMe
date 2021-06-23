module "subnetworks_list" {
    source = "..//subnetworks_list"

    project_id = var.host_project_id
}

## Example
## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_organization_policy
resource "google_project_organization_policy" "project_shared_vpc_restrict_subnetworks" {
    for_each    =  local.merge_target_project_ids
    project     = each.key
    constraint  = "compute.restrictSharedVpcSubnetworks"

    list_policy {
        allow {
            values = each.value
        }
    }
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_organization_policy
resource "google_folder_organization_policy" "folder_shared_vpc_restrict_subnetworks" {
    for_each    = local.merge_target_folder_ids
    folder      = each.key
    constraint  = "compute.restrictSharedVpcSubnetworks"

    list_policy {
        allow {
            values = each.value
        }
    }
}