resource "google_compute_network_peering" "peering" {
  for_each = {for peering in var.peerings: peering.name => peering}

  name         = each.key
  network      = each.value.local
  peer_network = each.value.remote
}
