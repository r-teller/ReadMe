# billing_account = "000000-123456-ABCDEF"

# organization_id = 1111111111111
## https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service

environments = {
        "i-haz-cloud-alpha"={
            primary_network = "10.10.0.0/24"
            pods_subnetwork = "10.10.10.0/24"
            svcs_subnetwork = "10.10.20.0/24"
            host_project    = null
            enabled_apis    = ["compute.googleapis.com","container.googleapis.com"]
            gke_master_net  = null
        },
        "i-haz-cloud-bravo"={
            primary_network = null
            pods_subnetwork = null
            svcs_subnetwork = null
            host_project    = "i-haz-cloud-alpha"
            gke_master_net  = "10.10.1.0/28"
            enabled_apis    = ["compute.googleapis.com","container.googleapis.com"]
        }
    }