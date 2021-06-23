# Shared VPC Restricted Subnetworks
This solution is comprised of two terriform modules. The restricted_subnetworks module is used to dynamically define which subnetworks are allowed based regex matching and is applied at either the Service-Project or Folder Hiearchy. The subnetworks_list module queries GCP API(s) for the specified Host Project (var.host_project_id) and discover all configured subnetworks within the specified Host Project. 

The subnetworks to project/folder mapping should be defined at the Host Project level to reduce the touchpoints required to update organization policies when subnetworks are added or removed. With the targets directory of the Host Project JSON files are used to define which subnets should be allowed based on regex matching (Subnetwork, Region and Network)

## Hierarchy
Example:
```
|---modules
    |---restrict_subnetworks
    \---subnetworks_list    
\---projects
    +---project-alpha-aaaa
        |   main.tf
        |   terraform.tf
        |   terraform.tfvars
        |   variables.tf
        |
        \---targets
                target-aaa.json
                target-bbb.json
                target-ccc.json
```

## Useful Links
- https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints#constraints-for-specific-services
- https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_organization_policy
- https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_organization_policy
- https://www.terraform.io/docs/language/functions/regex.html

Shared VPC connects projects within the same organization. Participating host and service projects cannot belong to different organizations. Linked projects can be in the same or different folders, but if they are in different folders the admin must have Shared VPC Admin rights to both folders. Refer to the Google Cloud resource hierarchy for more information about organizations, folders, and projects.
- https://cloud.google.com/vpc/docs/shared-vpc


## Prerequisites
Terraform can be downloaded from HashiCorp's [site](https://www.terraform.io/downloads.html).
Alternatively you can use your system's package manager.

The Terraform version is defined in the `terraform` block in `terraform.tf`

`gcloud` can be installed using Google's [documentation](https://cloud.google.com/sdk/docs/install).

## Running Terraform
Once Jenkins is created, this will run through a Jenkins job. In the meantime
use the following commands.

Set the following environment variables:
* GOOGLE_APPLICATION_CREDENTIALS=\<path to credentials file\>.
  * NOTE: For Jenkins you want to use `GCLOUD_KEYFILE_JSON` with the contents of
  the keyfile so that you don't have to manage files in a Jenkins job.
* If you have `gcloud` installed (you'll want to install it) set `GCLOUD_TF_DOWNLOAD ="never"`.
This cuts down on the time it takes to create the projects since Terraform won't 
try to install multiple copies of gcloud

See what will be created, destroyed and modified
`terraform plan`

To apply the changes
`terraform apply`

For Jenkins, you want to auto-approve the changes
`terraform apply -auto-approve`
