variable "project_id" {
    type        = string
    description = "Used to specify specific project to deploy to instead of creating unqiue project per deployment"
}

variable "vpc_name" {
    # type = string
}

variable "subnetwork" {
    # type = string
}

variable "random_id" { 
    # type = string
}

variable "environment" {
    type        = string
    description = "Unique environment name for this project, it will be used for resource naming"
}

variable "region" {
    type        = string
    description = "The GCP region for this subnetwork."
}

variable "gke_master_net" {
    type = string
    default = null
    description = "The Subnet range that should be assigned to the GKE Master nodes"
}