# General Networking
- The maximum number of secondary networks within a subnet is 30


```bash
#!/bin/bash
​
SUBNET_NAME=poetry-dev
​
C_CLASS="$(gcloud compute networks subnets list \
  --filter="name = $SUBNET_NAME" \
  --format="value(ipCidrRange)" \
  --verbosity=error | cut -d. -f1-3)."
​
gcloud asset search-all-resources | grep "networkIP: $C_CLASS" | wc -l
```


# Cloud Composer
## Networking

- The maximum number of private IP Cloud Composer environments that Cloud Composer can support is 12.
- The IPv4 CIDR range to use for the Airflow web server network should have a size of the netmask between 24 and 29
- The IPv4 CIDR range to use for the Cloud SQL network should have a size of the netmask not greater than 24
- The IPv4 CIDR range to use for the GKE Pods network should have a size of not less than 22
- The IPv4 CIDR range to use for the GKE Services network should have a size of not less than 27

### Useful Links
- creating Cloud Composer using gcloud
    - https://cloud.google.com/sdk/gcloud/reference/beta/composer/environments/create
- secondary ranges for composer GKE
    - https://cloud.google.com/composer/docs/how-to/managing/configuring-shared-vpc#important_notice
- ranges for Cloud SQL and Web servers
    - https://cloud.google.com/composer/docs/how-to/managing/configuring-private-ip#defaults

##

```bash
gcloud config set proxy/type http
gcloud config set proxy/address 127.0.0.1
gcloud config set proxy/port 8888
gcloud config set auth/disable_ssl_validation  True

gcloud config unset proxy/type
gcloud config unset proxy/address
gcloud config unset proxy/port
gcloud config set auth/disable_ssl_validation  False
```

```ps1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```