# Cloud Composer
## Networking

- The maximum number of private IP Cloud Composer environments that Cloud Composer can support is 12.
- The IPv4 CIDR range to use for the Airflow web server network should have a size of the netmask between 24 and 29
- The IPv4 CIDR range to use for the Cloud SQL network should have a size of the netmask not greater than 24
- The IPv4 CIDR range to use for the GKE Pods network should have a size of not less than 22
- The IPv4 CIDR range to use for the GKE Services network should have a size of not less than 27

### Note on creating Cloud Composer using gcloud
https://cloud.google.com/sdk/gcloud/reference/beta/composer/environments/create

### Note on secondary ranges for composer GKE
https://cloud.google.com/composer/docs/how-to/managing/configuring-shared-vpc#important_notice


### Note on ranges for Cloud SQL and Web servers
https://cloud.google.com/composer/docs/how-to/managing/configuring-private-ip#defaults

