# Challenge
Not able to connect to private clusters to manage services such as GKE or Cloud-SQL from a remote VPC or On-Premises. 

# Root Cause
Some services establish vpc peering between Google managed infrastructure and your VPC
- Services that establish a VPC Peer
    - GKE Private Clusters (https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)
    - Private Services access for Cloud SQL (https://cloud.google.com/sql/docs/mysql/configure-private-services-access#configure-access)
    - Private IP Cloud Composer (https://cloud.google.com/composer/docs/how-to/managing/configuring-private-ip)
<img src="./images/vpc-simple-design.png"  width="25%" height="25%" />

Only directly peered networks can communicate. Transitive peering is not supported. In other words, if VPC network N1 is peered with N2 and N3, but N2 and N3 are not directly connected, VPC network N2 cannot communicate with VPC network N3 over VPC Network Peering.
- https://cloud.google.com/vpc/docs/vpc-peering#restrictions

## Example Scenario
ihaz.cloud has two projects (alpha & bravo). The alpha project has a custom VPC that hosts a GKE private cluster and is peered with both the google managed vpc (hosts GKE Master nodes) and the bravo vpc. 

<img src="./images/vpc-transitive-issue.png"  width="25%" height="25%" />

# Workarounds
## Cloud VPN
The issue with transitive peering is the lack of routes exchangeed between peers. While GCP does support static routes it does not allow you to specify a VPC peer as the next hop. To workaround this we can leverage Cloud VPNs between the source VPC and destination VPC that is peered with the GCP Resource (GKE/Cloud-SQL/Cloud Composer) and then using Cloud Router we can inject the specific routes needed.

## Proxies
### Connecting to Cloud SQL using the docker image
- https://cloud.google.com/sql/docs/mysql/connect-docker
- https://cloud.google.com/sql/docs/postgres/connect-docker
- https://cloud.google.com/sql/docs/sqlserver/connect-docker

```bash
# If you are using the credentials provided by your Compute Engine instance, do not include the credential_file parameter and the -v <PATH_TO_KEY_FILE>:/config line.

# Always specify 127.0.0.1 prefix in -p so that the proxy is not exposed outside the local host. 
# The "0.0.0.0" in the instances parameter is required to make the port accessible from outside of the Docker container.

docker run -d \
  -v <PATH_TO_KEY_FILE>:/config \
  -p 127.0.0.1:3306:3306 \
  gcr.io/cloudsql-docker/gce-proxy:1.16 /cloud_sql_proxy \
  -instances=<INSTANCE_CONNECTION_NAME>=tcp:0.0.0.0:3306 -credential_file=/config
```

### Connecting to GKE
There doesn't appear to be a documented solution for connecting to private clusters within GCP but deploying nginx as a reverse proxy would work but requires maintenance if additional clusters are deployed

```bash
# Example nginx.conf for simple TCP forwarding
# This is TCP based instead of HTTP to reduce complexity with mutual tls

worker_processes auto;

error_log /var/log/nginx/error.log info;

events {
    worker_connections  1024;
}

stream {
  server {
    listen       443;
    
    proxy_pass      <Private Cluster Endpoint Address>;
  }
}
```