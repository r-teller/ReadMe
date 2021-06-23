output "private_endpoint" {
    value = try(google_container_cluster.primary[0].private_cluster_config[0].private_endpoint,null)
}
output "google_container_cluster" {
    value = try(google_container_cluster.primary[0],null)
}