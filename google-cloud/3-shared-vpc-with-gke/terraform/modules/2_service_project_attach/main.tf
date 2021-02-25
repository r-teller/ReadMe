data "google_project" "service_project" {
    project_id = var.service_project_id
}

data "google_client_config" "clent_config" {
}

data "http" "http_serviceusage_googleapis_com" {
    count = var.project_type == "service" ? 1 : 0
    url   = "https://serviceusage.googleapis.com/v1/projects/${var.service_project_id}/services?alt=json&filter=state%3AENABLED"
    request_headers = {
        accept          =  "application/json"
        authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
    }
}

locals {
    enabled_apis = [ for api in try(jsondecode(data.http.http_serviceusage_googleapis_com[0].body).services,[]): 
        (api.config.name)
    ] 

    iam_role_list = {
        "container.googleapis.com" = {  #<-- Required for Kubernetes Engine API
            "roles/compute.networkUser" = [
                "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com", 
            ],
            "roles/container.hostServiceAgentUser" = [
                "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com", 
            ]
        },
        "compute.googleapis.com" = {  #<-- Required for Compute Engine API
            "roles/compute.networkUser" = [
                "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com",
            ]
        },
        "cloudfunctions.googleapis.com" = {  #<-- Required for Cloud Functions API
            "roles/vpcaccess.user" = [
                "serviceAccount:service-${data.google_project.service_project.number}@gcf-admin-robot.iam.gserviceaccount.com",
            ],
        },
        "run.googleapis.com" = {  #<-- Required for Cloud Run Admin API
            "roles/vpcaccess.user" = [
                "serviceAccount:${data.google_project.service_project.number}@serverless-robot-prod.iam.gserviceaccount.com",
            ],
        },
        "composer.googleapiscom" = {  #<-- Required for Cloud Composer API
            "roles/compute.networkAdmin" = [
                "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
            ],
        }
        "dataproc.googleapis.com" = {  #<-- Required for Dataproc API
            "roles/compute.networkUser" = [
                "serviceAccount:service-${data.google_project.service_project.number}@dataproc-accounts.iam.gserviceaccount.com",
            ]
        },
    }

    iam_role_mappings = flatten([
        for service in keys(local.iam_role_list):[
            for role in keys(local.iam_role_list[service]):[
                for member in local.iam_role_list[service][role]:[
                    {
                            service = service
                            enabled = contains(local.enabled_apis, service)
                            role    = role
                            member  = member
                            key     = join("_",[role,member])      
                    }
                ] if contains(local.enabled_apis, service)
            ]
        ]
    ])
}

resource "google_compute_shared_vpc_service_project" "service_project_attach" {
    count = var.project_type == "service" ? 1 : 0

    host_project    = var.host_project_id
    service_project = var.service_project_id
}

resource "google_project_iam_member" "cloudservices" {
    count = var.project_type == "service" ? 1 : 0

    project = var.host_project_id
    role    = "roles/compute.networkUser"
    member  = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}

resource "google_project_iam_member" "iam_member" {
    for_each    = { for iam in local.iam_role_mappings: iam.key => iam }

    project     = var.host_project_id
    role        = each.value.role
    member      = each.value.member
}