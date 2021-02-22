## https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
resource "random_id" "id" {
    byte_length = 2
}

locals {
    project_id = var.project_id != null ? var.project_id : try(google_project.folder_project_id[0].project_id,google_project.org_project_id[0].project_id)
    
    pods_subnetwork_name    = "${var.environment}-subnetwork-secondary-pods-${random_id.id.hex}"
    svcs_subnetwork_name    = "${var.environment}-subnetwork-secondary-svcs-${random_id.id.hex}"
    # router_name = var.enable_cloud_nat 
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project
resource "google_project" "org_project_id" {
    ### Only create a new project if the project_id is not specified and folder_id is not specified
    count   = (var.project_id == null && var.folder_id == null) ? 1 : 0

    name                = "${var.environment}-proj-${random_id.id.hex}"
    project_id          = "${var.environment}-proj-${random_id.id.hex}"
    org_id              = var.org_id
    billing_account     = var.billing_account
    auto_create_network = false
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project
resource "google_project" "folder_project_id" {
    ### Only create a new project if the project_id is not specified and folder_id is specified
    count   = (var.project_id == null && var.folder_id != null) ? 1 : 0

    name                  = "${var.environment}-proj-${random_id.id.hex}"
    project_id            = "${var.environment}-proj-${random_id.id.hex}"
    folder_id             = var.folder_id

    auto_create_network   = false
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
resource "google_project_service" "gce" {
  project = local.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "gke" {
  project = local.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "network" {
    name                      = "${var.environment}-network-${random_id.id.hex}"
    project                   = var.project_id != null ? var.project_id : local.project_id

    auto_create_subnetworks   = false
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "subnetwork" {
    name            = "${var.environment}-subnetwork-${random_id.id.hex}"
    project         = var.project_id != null ? var.project_id : local.project_id

    ip_cidr_range   = var.primary_network
    region          = var.region
    network         = google_compute_network.network.id

    private_ip_google_access = true

    secondary_ip_range {
        range_name    = local.pods_subnetwork_name
        ip_cidr_range = var.pods_subnetwork
    }

    secondary_ip_range {
        range_name    = local.svcs_subnetwork_name
        ip_cidr_range = var.svcs_subnetwork
    }

}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "router_nat" {
    ## Checks if Cloud NAT should be enabled for this network, default is true
    count   = var.enable_cloud_nat ? 1 : 0

    name    = "${var.environment}-router-nat-${random_id.id.hex}"
    project = var.project_id != null ? var.project_id : local.project_id
    network = google_compute_network.network.id
    region  = var.region
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat" {
    ## Checks if Cloud NAT should be enabled for this network, default is true
    count   = var.enable_cloud_nat ? 1 : 0

    name                                = "${var.environment}-nat-${random_id.id.hex}"
    project                             = var.project_id != null ? var.project_id : local.project_id
    router                              = google_compute_router.router_nat[0].name
    region                              = var.region
    nat_ip_allocate_option              = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "firewall_iap_to_all_vms" {
    name    = "${var.environment}-firewall-iap-to-all-vms-${random_id.id.hex}"
    project = var.project_id != null ? var.project_id : local.project_id
    network = google_compute_network.network.id

    log_config {
        metadata = "EXCLUDE_ALL_METADATA"
    }

    allow {
        protocol  = "tcp"
        ports     = [22,443]
    }

    source_ranges = [
        "35.235.240.0/20",
    ]
}