variable "project_id" {
    type = string
    description = "Project_ID that you want to collect routing information from"
}

variable "vpc_name" {
    type = string
    description = "VPC that you want to build a routing table for"
  
}

variable "region" {
  type = string
  default = "us-central1"
  description = "Regions to collect route information from"
}