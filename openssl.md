## Create Cert and Key in single command
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

## Create openssl.cnf and setup root/intermediate directory
```bash
mkdir -p ./root_ca/newcerts ./root_ca/certs ./root_ca/private ./root_ca/crl
touch ./root_ca/index.txt
echo 'unique_subject = no' > ./root_ca/index.txt.attr
echo 00 > ./root_ca/serial

mkdir -p ./intermediate_ca/newcerts ./intermediate_ca/certs ./intermediate_ca/private ./intermediate_ca/crl
touch ./intermediate_ca/index.txt
echo 'unique_subject = no' > ./intermediate_ca/index.txt.attr
echo 00 > ./intermediate_ca/serial


cat <<EOF >> ./openssl.cnf 

# OpenSSL root CA configuration file.
# Copy to '/root/ca/openssl.cnf'.

[ ca ]
# 'man ca'
default_ca = INTERMEDIATE_CA_default

[ ROOT_CA_default ]
# Directory and file locations.
dir               = ./root_ca
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/ca.key
certificate       = \$dir/ca.crt

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 3650
preserve          = no
policy            = policy_strict

[ INTERMEDIATE_CA_default ]
# Directory and file locations.
dir               = ./intermediate_ca
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/ca.key
certificate       = \$dir/ca.crt

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 1825
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of 'man ca'.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the 'ca' man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the 'req' tool ('man req').
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = Washington
localityName_default            = Seattle
0.organizationName_default      = Acme Financial
organizationalUnitName_default  =
emailAddress_default            = no-reply@acmefinancial.net

[ v3_ca ]
# Extensions for a typical CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
default_days      = 730


[ crl_ext ]
# Extension for CRLs ('man x509v3_config').
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates ('man ocsp').
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning

EOF
```

## Create Root CA
```bash
openssl req -x509 -nodes -days 365 -sha256 -newkey rsa:2048 -keyout ./root_ca/ca.key -out ./root_ca/ca.crt -extensions 'v3_ca' -subj "/C=US/ST=Washington/L=Seattle/O=Sign Co/CN=Sign Co Root CA" -config ./openssl.cnf
```

## Create Intermediate CA
```bash
openssl genrsa -out ./intermediate_ca/ca.key 2048 -sha256

openssl req -new -sha256 -nodes -key ./intermediate_ca/ca.key -out ./intermediate_ca/ca.csr -extensions 'intermediate_ca_ext' -config <(
cat <<-EOF
    [req]
    default_bits = 2048
    prompt = no
    default_md = sha256
    distinguished_name = dn
    x509_extensions = intermediate_ca_ext

    [ dn ]
    C=US
    ST=Washington
    L=Seattle
    O=Sign Co
    CN=Sign Co Intermediate CA
    emailAddress=email@signco.net

    [ intermediate_ca_ext ]
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always,issuer
    basicConstraints = critical, CA:true, pathlen:0
    keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF
)

openssl ca -out ./intermediate_ca/ca.crt -name 'ROOT_CA_default' -extensions 'v3_intermediate_ca' -config ./openssl.cnf -batch -startdate 20000101120000Z -enddate 22220101120000Z -infiles ./intermediate_ca/ca.csr 
```


## Create Server Private Key
```bash
openssl genrsa -out cogswellcogs.key 2048
```

## Create Server Certificate Request
```bash
openssl req -new -sha256 -nodes -out cogswellcogs.csr -key cogswellcogs.key -extensions 'req_ext' -config <(
cat <<-EOF
    [req]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn

    [ dn ]
    C=US
    ST=Washington
    L=Seattle
    O=Cogswell Cogs
    emailAddress=email@cogswellcogs.shop
    CN = cogswellcogs.shop

    [ req_ext ]
    subjectAltName = @alt_names

    [ alt_names ]
    DNS.1 = *.cogswellcogs.shop
    DNS.2 = cogswellcogs.shop
EOF
)
```

## Sign Server Certificate Request with CA with custom start and end date
```bash
openssl ca -policy policy_loose -out ./cogswellcogs.crt -name 'INTERMEDIATE_CA_default' -config ./openssl.cnf -startdate 20180630120000Z -enddate 20190630120000Z -batch -extfile <(
cat <<-EOF 
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.cogswellcogs.shop
DNS.2 = cogswellcogs.shop
EOF
) -notext -infiles ./cogswellcogs.csr
```
## Convert PEM to PKCS12
```bash
openssl pkcs12 -export -out cogswellcogs.pfx -inkey cogswellcogs.key -in cogswellcogs.crt -certfile ./intermediate_ca/ca.crt -passin pass:cogswell -passout pass:cogswell
```
