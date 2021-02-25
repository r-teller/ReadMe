data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  count = var.gke_master_net != null ? 1 : 0

  name     = "${var.environment}-gke-${var.random_id.hex}"
  location     = data.google_compute_zones.available.names[1 % length(data.google_compute_zones.available.names)]
  project = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network = var.vpc_name
  subnetwork = var.subnetwork.id
  ip_allocation_policy {
    cluster_secondary_range_name = var.subnetwork.secondary_ip_range[0].range_name
    services_secondary_range_name = var.subnetwork.secondary_ip_range[1].range_name
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "10.0.0.0/8"
      display_name = "RFC 1918"
    }
    cidr_blocks {
      cidr_block = "172.16.0.0/12"
      display_name = "RFC 1918"
    }
    cidr_blocks {
      cidr_block = "192.168.0.0/16"
      display_name = "RFC 1918"
    }
  }
  default_max_pods_per_node = 16
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = var.gke_master_net
    master_global_access_config {
      enabled = true
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  count = var.gke_master_net != null ? 1 : 0

  name       =  "${var.environment}-node-pool-${var.random_id.hex}"

  cluster     = google_container_cluster.primary[0].name
  node_count  = 1
  project     = var.project_id
  location    = data.google_compute_zones.available.names[1 % length(data.google_compute_zones.available.names)]

  node_config {
    preemptible  = true
    machine_type = "e2-micro"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    # service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}