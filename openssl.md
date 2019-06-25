## Create CA
```bash
openssl genrsa -out ca.key 2048
openssl req -new -x509 -key ca.key -out ca.crt -config <(
cat <<-EOF
    [req]
    default_bits = 2048
    prompt = no
    default_md = sha256
    distinguished_name = dn

    [ dn ]
    C=US
    ST=Washington
    L=Seattle
    O=Sign This
    emailAddress=email@signthis.net
    CN = signthis.net
EOF
)

touch index.txt
echo 00 > serial
echo 'unique_subject = no' > index.txt.attr
mkdir newcerts

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
openssl ca -policy 'my_policy' -out cogswellcogs_20200625.crt -extensions 'req_ext' -name 'my_ca' -config <(
cat <<-EOF
    [ req_ext ]
    subjectAltName = @alt_names

    [ alt_names ]
    DNS.1 = *.cogswellcogs.shop
    DNS.2 = cogswellcogs.shop
    
    [ ca ]
    default_ca = my_ca

    [ my_ca ]
    #  a text file containing the next serial number to use in hex. Mandatory.
    #  This file must be present and contain a valid serial number.
    serial = ./serial

    # the text database file to use. Mandatory. This file must be present though
    # initially it will be empty.
    database = ./index.txt

    # specifies the directory where new certificates will be placed. Mandatory.
    new_certs_dir = ./newcerts

    # the file containing the CA certificate. Mandatory
    certificate = ./ca.crt

    # the file contaning the CA private key. Mandatory
    private_key = ./ca.key

    # the message digest algorithm. Remember to not use MD5
    default_md = sha1

    # for how many days will the signed certificate be valid
    default_days = 365

    # a section with a set of variables corresponding to DN fields
    policy = my_policy

    [ my_policy ]
    # if the value is "match" then the field value must match the same field in the
    # CA certificate. If the value is "supplied" then it must be present.
    # Optional means it may be present. Any fields not mentioned are silently
    # deleted.
    countryName = match
    stateOrProvinceName = supplied
    organizationName = supplied
    commonName = supplied
    organizationalUnitName = optional
    commonName = supplied
EOF
) -startdate 20190625120000Z -enddate 20200625120000Z -batch -infiles cogswellcogs.csr
```
