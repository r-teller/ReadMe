variable "OrgId" {
    type = string
}

data "google_client_config" "clent_config" {
}

data "http" "http_folders" {
  url   = "https://cloudresourcemanager.googleapis.com/v3/folders?alt=json&parent=organizations%2F${var.OrgId}"
  request_headers = {
    accept          = "application/json"
    authorization   = "Bearer ${data.google_client_config.clent_config.access_token}"
  }
}

locals {
    folder_id = [ for folder in jsondecode(data.http.http_folders.body).folders: folder if folder.displayName == "SANDBOX" ]
}

output "folder_id" {
    value = local.folder_id
}