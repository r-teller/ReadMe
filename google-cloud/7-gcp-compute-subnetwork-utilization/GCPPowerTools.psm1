#Requires -Version 6.0

# Core Module Imports
Import-Module -Name .\CoreModules\ComputeInstance.psm1
Import-Module -Name .\CoreModules\ComputeAddresses.psm1
Import-Module -Name .\CoreModules\ComputeBackendService.psm1
Import-Module -Name .\CoreModules\ComputeForwardingRule.psm1
Import-Module -Name .\CoreModules\ComputeSubnetwork.psm1
Import-Module -Name .\CoreModules\Utils.psm1
Import-Module -Name .\CoreModules\GCP.psm1

function Import-NetworkExtensionModules {
    param (
        
    )
    $modules = Get-ChildItem ./Extensions/Network -Filter "*.psm1"
    foreach ($module in $modules) {
        Import-Module -Name $module.FullName -Force -Global
    }
}

Import-NetworkExtensionModules