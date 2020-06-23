# Postgres DB Setup
Based on the current version of NGINX-Controller only PostgreSQL 9.5 is supported https://docs.nginx.com/nginx-controller/admin-guide/installing-nginx-controller/

## PostgreSQL install steps by OS

### Installing PostgreSQL 9.5 on CentOs 7
```bash
# Execute the following commands as a privilleged user
sudo -s

# Instal PostgreSQL repo 
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y

# Install PostgreSQL Client
yum install postgresql95 -y

# Install PostgreSQL Server
yum install postgresql95-server -y

# Initialize database
/usr/pgsql-9.5/bin/postgresql95-setup initdb

# By default PostgreSQL will only listen on localhost, we need to expose the service to external hosts
echo "listen_addresses='*'" >> /var/lib/pgsql/9.5/data/postgresql.conf

# Now that the PostgreSQL is listening to external requests we need to allow specific subnets to connect
## This will allow all clients to connect, this is not suggested for a production deployment
echo "host    all             all             0.0.0.0/0              md5" >> /var/lib/pgsql/9.5/data/pg_hba.conf

## This will allow a specifc clients to connect, replace 192.168.10.100 with the ip address of your controller
#echo "host    all             all             192.168.10.100/32              md5" >> /var/lib/pgsql/9.5/data/pg_hba.conf

# Enable PostgreSQL service
systemctl enable postgresql-9.5

# Start PostgreSQL service
systemctl start postgresql-9.5

# Exit privilleged user
exit
```

### Installing PostgreSQL 9.5 on Ubuntu 1804
```bash
# Execute the following commands as a privilleged user
sudo -s

# Add PostgreSQL to apt repo list
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list

# Add PostgreSQL key to apt list
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

# Update apt
apt-get update

# Install additional PostgreSQL modules
apt-get install postgresql-contrib -y

# Install PostgreSQL Server
apt-get install postgresql-9.5 -y


# By default PostgreSQL will only listen on localhost, we need to expose the service to external hosts
echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

# Now that the PostgreSQL is listening to external requests we need to allow specific subnets to connect
## This will allow all clients to connect, this is not suggested for a production deployment
echo "host    all             all             0.0.0.0/0              md5" >> /etc/postgresql/9.5/main/pg_hba.conf

## This will allow a specifc clients to connect, replace 192.168.10.100 with the ip address of your controller
#echo "host    all             all             192.168.10.100/32              md5" >> /etc/postgresql/9.5/main/pg_hba.conf

# Restart PostgreSQL service
service postgresql restart

# Exit privilleged user
exit
```

## Prepare Postgres DB for NGINX-Controller
```bash
# Execute the following commands as a Postgres user
sudo -i  -u postgres

# Launch postgresql client
psql
```

```sql
-- Create service account that nginx-controller will use
---- It is suggested that you change the password to something more secure/unique
CREATE USER naas WITH PASSWORD 'K33p0ut';

-- Grant the user permissions to create databases
ALTER USER naas CREATEDB;

-- Exit postgresql client
\q
```

# NGINX-Controller Host Setup
## NGINX-Controller prerequisite steps by OS

The following Linux utilities are required by the installation script. The script will let you know if any of the utilities are missing.

    curl or wget, jq, envsubst
    awk, bash (4.0 or later), getent, grep, gunzip, less, openssl, sed, tar
    base64, basename, cat, dirname, head, id, mkdir, numfmt, sort, tee


### Installing NGINX-Controller prerequisite on CentOs 7
#### Installing JQ
```bash
# Install Extra Packages for Enterprise Linux
sudo yum install epel-release -y

# Install jq
sudo yum install jq -y

# Install wget
sudo yum install wget -y
```

### Installing NGINX-Controller prerequisite on Ubuntu 1804
#### Installing JQ
```bash
# Install jq
sudo yum install jq -y
```

## NGINX-Controller install steps
```bash
# Ip address of the PostgreSQL instance that was setup earlier
databaseIp='192.168.10.101'
# Username of the service account created in the PostgreSQL instance that was setup earlier
databaseUser='naas'
# Password of the service account created in the PostgreSQL instance that was setup earlier
databasePass='K33p0ut'
# Ip address or FQDN that NGINX+ instances will use when calling home to the controller
controllerFQDN='controller.example.com'
# Username of the initial administrator, it must be in the form of an email address
controllerAdmin='admin@example.com'
# Password for the initial administrator, it is suggested that this is changed to something unique
controllerPass='Admin123'
# This is the ip address of the SMTP server that will be used for alerting
smtpIP='127.0.0.1'

# --accept-license -> This flag accepts the NGINX-Controller license
# --self-signed-cert -> This flag will generate a self-signed certificate for the controller
# --auto-install-docker -> This flag will auto install DockerCE

./install.sh \
    --accept-license \
    --self-signed-cert \
    --auto-install-docker \
    --database-host ${databaseIp} \
    --database-port 5432 \
    --database-user ${databaseUser} \
    --database-password ${databasePass} \
    --smtp-host ${smtpIP} \
    --smtp-port '25' \
    --smtp-authentication false \
    --smtp-use-tls false \
    --organization-name Example \
    --noreply-address 'noreply@example.com' \
    --admin-email ${controllerAdmin} \
    --admin-password ${controllerPass} \
    --fqdn  ${controllerFQDN}\
    --admin-firstname admin \
    --admin-lastname istrator \
    --tsdb-volume-type local
```

# NGINX Plus Setup
## NGINX Plus prerequisite steps by OS
### NGINX Plus prerequisite on CentOs 7
Issues have been observed with selinux preventing NGINX-Controller agent from making changes to the local file system
```bash
# Execute the following commands as a privilleged user
sudo -s

# Install selinux tools
yum install setools-console -y

# Create nginx.te file that will be used for configuring selinux
cat << EOF > ./nginx-plus-module-f5-metrics.te
module nginx-plus-module-f5-metrics 1.0;

require {
        type httpd_t;
        type httpd_config_t;
        class file append;
}

#============= httpd_t ==============
allow httpd_t httpd_config_t:file append;
EOF

# Convert te file into module
checkmodule -M -m -o ./nginx-plus-module-f5-metrics.mod ./nginx-plus-module-f5-metrics.te

# Compile se module
semodule_package -o ./nginx-plus-module-f5-metrics.pp -m ./nginx-plus-module-f5-metrics.mod

# Import selinux policy
semodule -i ./nginx-plus-module-f5-metrics.pp

exit
```
# NGINX-Controller Managed Instances
## NGINX-Controller-Agent Prerequisite check
```bash
#!/bin/bash

# Get OS information
get_os_name() {

    centos_flavor="centos"

    # Use lsb_release if possible
    if command -V lsb_release >/dev/null 2>&1; then
        os=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
        release=$(lsb_release -rs | sed 's/\..*$//')

        if [ "$os" = "redhatenterpriseserver" ] || [ "$os" = "oracleserver" ]; then
            os="centos"
            centos_flavor="red hat linux"
        fi
    # Otherwise it's getting a little bit more tricky
    else
        if ! ls /etc/*-release >/dev/null 2>&1; then
            os=$(uname -s |
                tr '[:upper:]' '[:lower:]')
        else
            os=$(cat /etc/*-release | grep '^ID=' |
                sed 's/^ID=["]*\([a-zA-Z]*\).*$/\1/' |
                tr '[:upper:]' '[:lower:]')

            if [ -z "$os" ]; then
                if grep -i "oracle linux" /etc/*-release >/dev/null 2>&1 ||
                    grep -i "red hat" /etc/*-release >/dev/null 2>&1; then
                    os="rhel"
                else
                    if grep -i "centos" /etc/*-release >/dev/null 2>&1; then
                        os="centos"
                    else
                        os="linux"
                    fi
                fi
            fi
        fi
    fi
    
    case "$os" in
        ubuntu | debian | centos | rhel | ol | amzn)
            echo "[INFO] $os is supported"
            ;;
        *)
            echo "[ERROR] Unknown OS"
            exit 2
    esac
}


# Check if package is installed
function package_check() {
    case "$os" in
        ubuntu | debian)
            DPKG_RESULTS=$(dpkg-query -W --showformat='${Version}\n' $PKG_NAME 2>/dev/null)
            if [ "" = "$DPKG_RESULTS" ]; then
                echo "[ERROR] $PKG_NAME is not installed"
                PKG_VERSION="NOT-INSTALLED"
            else
                echo "[OKAY] $PKG_NAME is installed"
                PKG_VERSION=$DPKG_RESULTS
            fi
            ;;
        amzn | centos | rhel | ol)
            RPM_RESULTS=$(rpm -q --queryformat "%{VERSION}\n" $PKG_NAME)
            if [[ $RPM_RESULTS == *'not installed' ]]; then
                echo "[ERROR] $PKG_NAME is not installed"
                PKG_VERSION="NOT-INSTALLED"
            else
                echo "[OKAY] $PKG_NAME is installed"
                PKG_VERSION=$RPM_RESULTS
            fi
            ;;
    esac
}

# Check OS
get_os_name

## Check NGINX-Plus is installed
PKG_NAME=nginx-plus
package_check

## Check NGINX-Plus version
if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    case "$PKG_VERSION" in
        19*)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
        20*)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
        21*)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
        22*)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
        *)
            echo "[ERROR] $PKG_NAME version is not supported --> ${PKG_VERSION}"
            ;;
    esac
fi 


## Check libxerces is installed
PKG_NAME=libxerces-c3.2
package_check

## Check libxerces version
if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    case "$PKG_VERSION" in
        *)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
    esac
fi

## Check Python2.7 is installed
PKG_NAME=python2.7
package_check

## Check libxerces version
if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    case "$PKG_VERSION" in
        *)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
    esac
fi

# Commented out until 3.7 released
# Check GoLang is installed
# PKG_NAME=golang-go
# package_check

# Check libxerces version
# if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    # case "$PKG_VERSION" in
        # *)
            # echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            # ;;
    # esac
# fi


## Check OpenSSL is installed
PKG_NAME=openssl
package_check

## Check libxerces version
if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    case "$PKG_VERSION" in
        *)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
    esac
fi

## Check Curl is installed
PKG_NAME=curl
package_check

## Check libxerces version
if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    case "$PKG_VERSION" in
        *)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
    esac
fi

## Check Curl is installed
PKG_NAME=cloud-init
package_check

## Check libxerces version
if [ "$PKG_VERSION" != "NOT-INSTALLED" ]; then 
    case "$PKG_VERSION" in
        *)
            echo "[OKAY] $PKG_NAME version is supported --> ${PKG_VERSION}"
            ;;
    esac
fi
```