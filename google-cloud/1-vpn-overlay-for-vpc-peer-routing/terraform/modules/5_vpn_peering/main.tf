resource "random_id" "hub_spoke_ha_vpn_suffix" {
  byte_length = 2
}

resource "random_integer" "random_seed" {
  min = 0
  max = 50000
}

resource "random_integer" "random_bgp_asn" { 
  min = 4200000000
  max = 4294967293
  seed  = "${count.index + random_integer.random_seed.result}"
  count = 2
}

resource "random_integer" "tunnel_subnet_bits" {
  min = 0
  max = 4095
  seed  = "${count.index + random_integer.random_seed.result}"
  count = 2
}

locals {
  subnets = {
    tunnel_0 = cidrsubnet("169.254.0.0/16",14, random_integer.tunnel_subnet_bits.0.result)
  }
}

module "module_local_to_remote" {
  source            = "../_cloud_vpn"
  name              = "${var.networks.first.name}-vpngw-to--${var.networks.second.name}-vpngw"
  region            = var.networks.first.region
  network           = var.networks.first.network
  project_id        = var.networks.first.project_id
  peer_gcp_gateway  = module.module_remote_to_local_vpn.self_link

  router_asn        = random_integer.random_bgp_asn[0].result
  router_advertise_config = {
    mode  = "CUSTOM"
    ip_ranges = var.networks.first.advertised_networks
    groups = []
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = cidrhost(local.subnets.tunnel_0,2)
        asn     = random_integer.random_bgp_asn[1].result
      }      
      bgp_peer_options = {
        advertise_groups    = []
        advertise_ip_ranges = {}
        advertise_mode      = "CUSTOM"
        route_priority      = 1000
      }

      bgp_session_range = "${cidrhost(local.subnets.tunnel_0,1)}/30"
      ike_version       = 2
      vpn_gateway_interface = 0
      peer_external_gateway_interface = null
      shared_secret     = ""
    }
  }
}

module "module_remote_to_local_vpn" {
  source            = "../_cloud_vpn"

  name              = "${var.networks.second.name}-vpngw-to--${var.networks.first.name}-vpngw"
  region            = var.networks.second.region
  network           = var.networks.second.network
  project_id        = var.networks.second.project_id
  peer_gcp_gateway  = module.module_local_to_remote.self_link

  router_asn        = random_integer.random_bgp_asn[1].result
  router_advertise_config = {
    mode  = "CUSTOM"
    ip_ranges = var.networks.second.advertised_networks
    groups = []
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = cidrhost(local.subnets.tunnel_0,1)
        asn     = random_integer.random_bgp_asn[0].result
      }
      bgp_peer_options  = null
      bgp_session_range = "${cidrhost(local.subnets.tunnel_0,2)}/30"
      ike_version       = 2
      vpn_gateway_interface = 0
      peer_external_gateway_interface = null
      shared_secret     = module.module_local_to_remote.random_secret
    }
  }
}
