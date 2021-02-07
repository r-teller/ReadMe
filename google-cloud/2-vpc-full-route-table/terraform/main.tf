locals {
    vpc_filter  = urlencode("network=\"https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/networks/${var.vpc_name}\"")
}

data "google_project" "service_project" {
    project_id = var.project_id
}

data "google_client_config" "clent_config" {
}

# ## Get VPC Information
data "http" "http_vpc_networks" {
  url   = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/global/networks/${var.vpc_name}"
  request_headers = {
    accept          =  "application/json"
    authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
  }
}

locals {
    vpc_peerings = [ for peer in jsondecode(data.http.http_vpc_networks.body).peerings: {
            "name": peer.name
            "state": peer.state
            "network": peer.network
            "importCustomRoutes": peer.importCustomRoutes
            "exportCustomRoutes": peer.exportCustomRoutes
        } if peer.state == "ACTIVE"
    ]
}

data "http" "http_vpc_peer_routes" {
    for_each   = {for vpc_peer in local.vpc_peerings: vpc_peer.name => vpc_peer }
    url = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/global/networks/${var.vpc_name}/listPeeringRoutes?region=${var.region}&direction=INCOMING&peeringName=${each.value.name}"
    request_headers = {
        accept          =  "application/json"
        authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
    }
}

locals {
    vpc_peer_imported_routes = flatten([
        for response_key in keys(data.http.http_vpc_peer_routes): [
            for k,v in jsondecode(data.http.http_vpc_peer_routes[response_key]["body"]):{items=v,"vpc_peer_name"=response_key} if k =="items"
        ]
    ])
    vpc_imported_routes = flatten([
        for route in local.vpc_peer_imported_routes:[
            for item in route.items:{
                network = var.vpc_name
                destRange   = item.destRange
                priority    = item.priority
                nextHopType = "Peer"
                nextHop     = route.vpc_peer_name
                kind        = "compute#exchangedPeeringRoutesList"
                routeType  = "vpc_imported_routes"
            }
        ]
    ])
}

data "http" "http_vpc_routes" {
    url = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/global/routes?filter=(${local.vpc_filter})&region=${var.region}"
    request_headers = {
        accept          =  "application/json"
        authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
    }
}

locals {
    vpc_native_routes = [for route in jsondecode(data.http.http_vpc_routes.body).items:{
        network = var.vpc_name
        destRange = route.destRange
        priority = route.priority
        nextHopType = contains(keys(route),"nextHopNetwork") ? "Local" : contains(keys(route),"nextHopPeering") ? "Peer" : "Default"
        nextHop = contains(keys(route),"nextHopNetwork") ? route.nextHopNetwork : contains(keys(route),"nextHopPeering") ? route.nextHopPeering : route.nextHopGateway
        kind = route.kind
        routeType = "vpc_native_route"
    }]
}

## Build a list of all routers created within the specified VPC
data "http" "http_vpc_routers" {
    url = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/routers?filter=(${local.vpc_filter})"
    request_headers = {
        accept          =  "application/json"
        authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
    }
}

## Get the status of all routers created within the specified VPC
data "http" "http_vpc_router_status" {
    for_each = toset(jsondecode(data.http.http_vpc_routers.body).items[*].name)
    url = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/routers/${each.key}/getRouterStatus"
    request_headers = {
        accept          =  "application/json"
        authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
    }
}

locals {
    vpc_bgp_learned_routes = flatten([
        for response_key in keys(data.http.http_vpc_router_status): [
            for k,v in jsondecode(data.http.http_vpc_router_status[response_key]["body"]): v.bestRoutesForRouter if (k=="result" && try(contains(keys(v),"bestRoutesForRouter"),false))
        ]
    ])
    vpc_bgp_routes = [
        for route in local.vpc_bgp_learned_routes:{
            network     = var.vpc_name
            destRange   = route.destRange
            priority    = route.priority
            nextHopType = "BGP"
            nextHop     = route.nextHopIp
            kind        = route.kind
            routeType   = "vpc_bgp_routes"
        }
    ]
}

locals {
    route_table = concat(local.vpc_native_routes,local.vpc_imported_routes,local.vpc_bgp_routes)
}


output "route_table" {
    value = local.route_table
}