# Terraform through a Proxy
## PowerShell
```ps
$env:HTTP_PROXY=http://127.0.0.1:8888
$env:HTTPs_PROXY=http://127.0.0.1:8888
```

# Providers
## GCP
### Auth
'''bash
gcloud auth application-default login
'''

# GCP Direct API Call
```terraform
## This section allows you to grab your current oAuth token
data "google_client_config" "clent_config" {    
}

## This section interacts with the GCP API
data "http" "http_serviceusage_googleapis_com" {
  url = "https://serviceusage.googleapis.com/v1/projects/${var.project_id}/services?alt=json&filter=state%3AENABLED"
  request_headers = {
    accept =  "application/json"
    authorization = "Bearer ${data.google_client_config.clent_config.access_token}"
  }
}

## This section converts the response into a useable format for other resources to use
locals {
  enabled_apis = [ for api in jsondecode(data.http.http_serviceusage_googleapis_com.body).services: {
        name = api.config.name  
        state = api.state
  }]
}
```