variable "environment" {
    type        = string
    description = "Unique environment name for this project, it will be used for resource naming"
}

variable "region" {
    type        = string
    description = "The GCP region for this subnetwork."
    default     = "us-central1"
}

variable "project_id" {
    type        = string
    description = "Used to specify specific project to deploy to instead of creating unqiue project per deployment"
    default     = null
}

variable "org_id" {
    type        = number
    description = "The numeric ID of the organization this project belongs to. If the folder_id is specified, then the project is created under the specified folder."
    default     = null
}

variable "folder_id" {
    type        = number
    description = "The numeric ID of the folder this project should be created under."
    default     = null
}

variable "enable_cloud_nat" {
    type        = bool
    description = "Used to deterime if Cloud NAT should be deployed for this environment"
    default     = true
}

variable "primary_network" {
    type        = string
    description = "The range of internal addresses that are owned by this subnetwork."
}

variable "pods_subnetwork" {
    type        = string
    description = "The range of secondary addresses that will be used for GKE pods"
}

variable "svcs_subnetwork" {
    type        = string
    description = "The range of secondary addresses that will be used for GKE services"
}

variable "billing_account" {
    type        = string
    default     = null
    description = "The alphanumeric ID of the billing account this project belongs to."
}