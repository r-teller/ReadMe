# billing_account = "000000-123456-ABCDEF"

## Only one of the following 3 items are required for sucesful deployment
# organization_id = 1111111111111
# folder_id  = 1111111111111
# project_id = 1111111

vpn_peerings = [
    {
        first="i-haz-cloud-bravo",
        second="i-haz-cloud-alpha",
    }
]  

environments = {
        "i-haz-cloud-alpha"={
            gke_master_net  = "10.10.1.0/28"
            primary_network = "10.10.0.0/24"
            pods_subnetwork = "10.10.10.0/24"
            svcs_subnetwork = "10.10.20.0/24"
            vpc_peers = ["i-haz-cloud-bravo","i-haz-cloud-charlie"]
        },
        "i-haz-cloud-bravo"={
            gke_master_net  = null
            primary_network = "10.11.0.0/24"
            pods_subnetwork = "10.11.10.0/24"
            svcs_subnetwork = "10.11.20.0/24"
            vpc_peers = ["i-haz-cloud-alpha","i-haz-cloud-charlie"]
        },
        "i-haz-cloud-charlie"={
            gke_master_net  = null
            primary_network = "10.12.0.0/24"
            pods_subnetwork = "10.12.10.0/24"
            svcs_subnetwork = "10.12.20.0/24"
            vpc_peers = ["i-haz-cloud-alpha","i-haz-cloud-bravo"]
        }
    }