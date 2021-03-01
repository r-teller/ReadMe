output "network" {
  description = "Network Object"
  value = google_compute_network.network
}

output "subnetwork" {
    description = "Subnetwork Object"
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