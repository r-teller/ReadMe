data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "jump_host" {
    name     = "${var.environment}-jump-host-${var.random_id.hex}"
    project  = var.project_id
    machine_type = "e2-micro"
    zone     = data.google_compute_zones.available.names[1 % length(data.google_compute_zones.available.names)]

    network_interface {
        network            = var.vpc_name
        subnetwork         = var.subnetwork.self_link
    }
    scheduling {
      preemptible = true
      automatic_restart = false
    }
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }
}