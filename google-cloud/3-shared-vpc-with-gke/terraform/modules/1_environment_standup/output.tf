output "network_self_link" {
  description = "Network self link"
  value = try(google_compute_network.network[0].self_link,null)
}

output "subnetwork_self_link" {
    description = "Subnetwork Self Link"
    value = try(google_compute_subnetwork.subnetwork[0],null)
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