# Searching for AMI

## Search for Centos Linux 7 AMI and return AmiID, Name and ProductCodeID in the results
```bash
aws ec2 describe-images  --region us-west-1 --filters "Name=name,Values=CentOS Linux 7*2002*" --query "Images[].{Name:Name,ProductCodeId:ProductCodes[0].ProductCodeId,AmiId:ImageId}"

[
    {
        "AmiId": "ami-098f55b4287a885ba", 
        "ProductCodeId": "aw0evgkw8e5c1q413zgy5pjce", 
        "Name": "CentOS Linux 7 x86_64 HVM EBS ENA 2002_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-0042af67f8e4dcc20.4"
    }
]
```

## Search all regions based on filter criteria
```bash
    for region in `aws ec2 describe-regions --query "Regions[].{Name:RegionName}" --output text`
    do    
        ami=$(aws ec2 describe-images  --region $region \
            --filters "Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce" \
            --filters "Name=name,Values=CentOS Linux 7*2002*" \
            --query "Images[].{ImageId:ImageId}" | jq '.[0].ImageId')
        printf "\"${region}\": {\"AMI\": ${ami}},\n"
    done


    "eu-north-1": {"AMI": "ami-05788af9005ef9a93"},
    "ap-south-1": {"AMI": "ami-026f33d38b6410e30"},
    "eu-west-3": {"AMI": "ami-0cb72d2e599cffbf9"},
    "eu-west-2": {"AMI": "ami-09e5afc68eed60ef4"},
    "eu-west-1": {"AMI": "ami-0b850cf02cc00fdc8"},
    "ap-northeast-2": {"AMI": "ami-06e83aceba2cb0907"},
    "ap-northeast-1": {"AMI": "ami-06a46da680048c8ae"},
    "sa-east-1": {"AMI": "ami-0b30f38d939dd4b54"},
    "ca-central-1": {"AMI": "ami-04a25c39dc7a8aebb"},
    "ap-southeast-1": {"AMI": "ami-07f65177cb990d65b"},
    "ap-southeast-2": {"AMI": "ami-0b2045146eb00b617"},
    "eu-central-1": {"AMI": "ami-0e8286b71b81c3cc1"},
    "us-east-1": {"AMI": "ami-0affd4508a5d2481b"},
    "us-east-2": {"AMI": "ami-01e36b7901e884a10"},
    "us-west-1": {"AMI": "ami-098f55b4287a885ba"},
    "us-west-2": {"AMI": "ami-0bc06212a56393ee1"},    
```


# Expand volume size
```bash
sudo growpart /dev/nvme0n1 1
sudo resize2fs /dev/nvme0n1p1 
```