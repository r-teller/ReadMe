# GCP Power Tools [PowerShell](https://github.com/PowerShell/PowerShell) Module

## Design choices 
This code base is written in PowerShell using the module format to break code apart similar to what we see in python and javascript and most other languages. The idea is to create a new module that maps to a google cloud asset type when that asset becomes relevant to our operators. Each module will implement a artifact collection function using this [template](./Templates/CollectionTemplate.ps1). All collection jobs run in the background in their own thread - once complete they are saved to ***./Workspaces/CURRENTENGAGEMENT/Artifacts/ASSETTYPE.xml***. All checks and enumeration is done by using the PowerShell pipeline. Each artifact that implements checks will use the style [here](./Templates/ArtifactProcessingTemplate.ps1). 

### Dependencies 
- [gcloud](https://cloud.google.com/sdk/docs/install)
- [PowerShell](https://github.com/PowerShell/PowerShell)
- [List permissions here for tool](https://cloud.google.com/iam/docs/understanding-roles)
- [GCP ORG](https://cloud.google.com/resource-manager/docs/creating-managing-organization)

### Example usage
```powershell
pwsh # assuming you have downloaded and installed powershell
gcloud auth login
Import-Module ./GCPPowerTools.psm1
Get-Command -Module GCPPowerTools # List available commands imported from module
New-GCPSession # leverages auth in current shell and sets up some global variables 
Get-ComputeSubnetworkUtilization 
```

## Networking Stuff
### Discovery Current Subnetwork Utilziation within your Organization
```powershell
$utilization=Get-ComputeSubnetworkUtilization

## This snippet will show all Networks where one ore more subnetworks have exceeded 50% utilziation
$utilization | Where-Object {
    $_.networks.subnetworks.utilization.hostsPercentage.trim('%') -gt 50
    } |Select-Object {$_.projectId, $_.networks.subnetworks.utilization.hostsPercentage.trim('%')}  
```

### Useful Ref links
- https://cloud.google.com/asset-inventory/docs/supported-asset-types
- https://cloud.google.com/asset-inventory/docs/listing-assets#api_1
- https://cloud.google.com/compute/docs/reference/rest/v1 