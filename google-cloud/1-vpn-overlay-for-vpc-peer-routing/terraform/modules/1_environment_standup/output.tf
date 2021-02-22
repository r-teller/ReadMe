output "network_self_link" {
  description = "Network self link"
  value = google_compute_network.network.self_link
}

output "subnetwork_self_link" {
    description = "Subnetwork Self Link"
    value = google_compute_subnetwork.subnetwork
}

output "advertised_networks" {
    description = "Networks available in this network"
    value = {
        (var.primary_network)="Primay Network",
        (var.pods_subnetwork)="Pods Subnetwork",
        (var.svcs_subnetwork)="Svcs Subnetwork",
    }
}

output "project_id" {
  description = "Project ID"
  value = local.project_id
}

output "environment" {
    value = var.environment
}

output "region" {
    value = var.region
}

output "id" {
    value = random_id.id
}