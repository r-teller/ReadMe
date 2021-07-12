Enum IpAddressConsumer {
    Instance
    ForwardingRule
    OtherAddress
}

Enum SubnetworkPurpose {
    PRIVATE
    INTERNAL_HTTPS_LOAD_BALANCER
    PRIVATE_SERVICE_CONNECTION
}

class IpAddress_v4 {
    [string] $name
    [string] $network
    [string] $subnetwork
    [string] $interface
    [string] $networkIp
    [string] $zone
    [string] $region
    [string] $state
    [string] $projectId
    [int] $index
    [IpAddressConsumer] $consumer
}

class Subnetwork {
    [string] $name
    [string] $ipCidrRange="255.255.255.255/32"
    [string] $network
    [string] $region
    [string] $projectId
    [SubnetworkPurpose] $purpose
    [int] $index
    [IpAddress_v4[]] $instances = @()
    [IpAddress_v4[]] $forwardingRules = @()
    [IpAddress_v4[]] $otherAddresses = @()
    [string] $utilization = "0.0%"
    $totalUtilization = @{}

    CalculateUtilization(){
        $instanceCount = $this.instances.count
        $forwardingRuleCount = $this.forwardingRules.count
        $otherAddressCount = $this.otherAddresses.count

        $hostsMax = [math]::Pow(2,(32 - $this.ipCidrRange.split("/")[1] )) - 2
        $hostsUsed = ($instanceCount + $forwardingRuleCount + $otherAddressCount) +4
        $this.utilization =  ($hostsUsed / $hostsMax).ToString("P")
        $this.totalUtilization = @{
            hostsMax = $hostsMax
            hostsUsed = $hostsUsed
            instances = $instanceCount
            forwardingRules = $forwardingRuleCount
            otherAddresses = $otherAddressCount
        }
    }
}

class Network {
    [string] $name
    [string] $projectId
    [int] $index
    [Subnetwork[]] $subnetworks = @()
}

class Project {
    [string] $projectId
    [int] $index
    [Network[]] $networks = @()
}

# Parsing functions 
function Get-ComputeSubnetworkUtilization {
    param (
        [object]$ComputeAddresses,
        [object]$ComputeInstances,
        [object]$ComputeForwardingRules,
        [object]$ComputeSubnetworks
    )
    Begin {
        $jobStatus = @{}
        # Check if $ComputeInstances param was set or if modulue should be called directly
        if ($ComputeAddresses) {            
            $jobStatus.Add("ComputeAddresses","Ready")
        }else {
            $ComputeAddresses = Get-ComputeAddresses
            if ($ComputeAddresses) {
                $jobStatus.Add("ComputeAddresses","Ready")
            } else {                
                $jobStatus.Add("ComputeAddresses","NotReady")
            }
        }

        # Check if $ComputeInstances param was set or if modulue should be called directly
        if ($ComputeInstances) {            
            $jobStatus.Add("ComputeInstances","Ready")
        }else {
            $ComputeInstances = Get-ComputeInstances
            if ($ComputeInstances) {
                $jobStatus.Add("ComputeInstances","Ready")
            } else {                
                $jobStatus.Add("ComputeInstances","NotReady")
            }
        }

        # Check if $ComputeForwardingRules param was set or if modulue should be called directly
        if ($ComputeForwardingRules){
            $jobStatus.Add("ComputeForwardingRules","Ready")
        } else {
            $ComputeForwardingRules = Get-ComputeForwardingRules
            if ($ComputeForwardingRules) {
                $jobStatus.Add("ComputeForwardingRules","Ready")
            } else {                
                $jobStatus.Add("ComputeForwardingRules","NotReady")
            }
        }

        # Check if $ComputeSubnetworks param was set or if modulue should be called directly
        if ($ComputeSubnetworks) {
            $jobStatus.Add("ComputeSubnetworks","Ready")
        } else {
            $ComputeSubnetworks = Get-ComputeSubnetworks
            if ($ComputeSubnetworks) {
                $jobStatus.Add("ComputeSubnetworks","Ready")
            } else {                
                $jobStatus.Add("ComputeSubnetworks","NotReady")
            }
        }

        if ($jobStatus.ContainsValue("NotReady")) {
            Write-Host "One of the Artifacts below is not ready yet"
            $jobStatus.GetEnumerator()
            Break
        }
    }
 
    Process {
        [system.collections.ArrayList]$allProjects = @()
        $projects = @{}
        foreach ($_subnetwork in $ComputeSubnetworks) {
            $subnetwork = [Subnetwork]::new()
            $subnetwork.name = $_subnetwork.name
            $subnetwork.region = $_subnetwork.region.split("/")[-1]
            $subnetwork.ipCidrRange = $_subnetwork.ipCidrRange
            $subnetwork.network = $_subnetwork.network.split("/")[-1]
            $subnetwork.projectId = $_subnetwork.network.split("/")[6]
            $subnetwork.purpose = $_subnetwork.purpose

            if (($projects.ContainsKey($subnetwork.projectId)) -eq $false) {
                $project = [Project]::new()
                $project.projectId = $subnetwork.projectId
                $project.index = $projects.count

                $projects.add($project.projectId,$project)                
            }
            
            $_network = $projects[$subnetwork.projectId].networks | Where-Object {$_.name -eq $subnetwork.network}
            if (($_network.count) -eq $false) {
                $network = [Network]::new()
                $network.name = $subnetwork.network
                $network.projectId = $subnetwork.projectId
                $network.index = $projects[$subnetwork.projectId].networks.count

                $_network = $network
                $projects[$subnetwork.projectId].networks += $network
            }
            $subnetwork.index = $projects[$subnetwork.projectId].networks[$_network.index].subnetworks.count
            $projects[$subnetwork.projectId].networks[$_network.index].subnetworks += $subnetwork            
        }
        
        foreach ($_address in $ComputeAddresses | Where-Object {$null -eq $_.users -and $_.addressType -ne "EXTERNAL"} ) {
            $ipAddress_v4 = [IpAddress_v4]::new()
            $ipAddress_v4.name = $_address.name

            $ipAddress_v4.subnetwork = $_address.subnetwork.split("/")[-1]
            $ipAddress_v4.networkIp = $_address.address
            $ipAddress_v4.region = $_address.region.split("/")[-1]
            $ipAddress_v4.projectId = $_address.selfLink.split("/")[6]
            $ipAddress_v4.consumer = "OtherAddress"

            $_subnetworkProjectId = $_address.subnetwork.split("/")[6]
            
            $ipAddress_v4.network =  $projects[$_subnetworkProjectId].networks | Where-Object {$_.subnetworks.name -eq $ipAddress_v4.subnetwork} | ForEach-Object {
                foreach($_subnetwork in $_.subnetworks) {
                    if ($_subnetwork.name -eq $ipAddress_v4.subnetwork -and $_subnetwork.region -eq  $ipAddress_v4.region){
                        $_.name
                    }
                }
            }

            $_network = $projects[$_subnetworkProjectId].networks | Where-Object {$_.name -eq $ipAddress_v4.network}
            $_subnetwork = $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks | Where-Object {$_.name -eq $ipAddress_v4.subnetwork -and $_.region -eq $ipAddress_v4.region}
            $ipAddress_v4.index = $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks[$_subnetwork.index].$otherAddresses.count
            $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks[$_subnetwork.index].otherAddresses += $ipAddress_v4
        }

        foreach ($_instance in $ComputeInstances) {
            foreach ($_interface in $_instance.NetworkInterfaces) {
                $ipAddress_v4 = [IpAddress_v4]::new()
                $ipAddress_v4.name = $_instance.name
                $ipAddress_v4.network = $_interface.network.split("/")[-1]
                $ipAddress_v4.subnetwork = $_interface.subnetwork.split("/")[-1]
                $ipAddress_v4.interface = $_interface.name
                $ipAddress_v4.networkIp = $_interface.networkIP
                $ipAddress_v4.state =  $_instance.status
                $ipAddress_v4.zone = $_instance.zone
                $ipAddress_v4.region = $_interface.subnetwork.split("/")[8]
                $ipAddress_v4.projectId = $_instance.selfLink.split("/")[6]
                $ipAddress_v4.consumer = "Instance"

                $_subnetworkProjectId = $_interface.subnetwork.split("/")[6]
                $_network = $projects[$_subnetworkProjectId].networks | Where-Object {$_.name -eq $ipAddress_v4.network}
                $_subnetwork = $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks | Where-Object {$_.name -eq $ipAddress_v4.subnetwork -and $_.region -eq $ipAddress_v4.region}
                $ipAddress_v4.index = $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks[$_subnetwork.index].instances.count
                $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks[$_subnetwork.index].instances += $ipAddress_v4
            }
        }

        foreach ($_forwardingRule in $ComputeForwardingRules | Where-Object {$_.loadBalancingScheme -ne "EXTERNAL"} ) {
            $ipAddress_v4 = [IpAddress_v4]::new()
            $ipAddress_v4.name = $_forwardingRule.name
            $ipAddress_v4.network = $_forwardingRule.network.split("/")[-1]
            $ipAddress_v4.subnetwork = $_forwardingRule.subnetwork.split("/")[-1]
            $ipAddress_v4.networkIp = $_forwardingRule.IPAddress
            $ipAddress_v4.region = $_forwardingRule.region.split("/")[-1]
            $ipAddress_v4.projectId = $_forwardingRule.selfLink.split("/")[6]
            $ipAddress_v4.consumer = "ForwardingRule"

            $_subnetworkProjectId = $_forwardingRule.subnetwork.split("/")[6]
            $_network = $projects[$_subnetworkProjectId].networks | Where-Object {$_.name -eq $ipAddress_v4.network}
            $_subnetwork = $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks | Where-Object {$_.name -eq $ipAddress_v4.subnetwork -and $_.region -eq $ipAddress_v4.region}
            $ipAddress_v4.index = $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks[$_subnetwork.index].forwardingRules.count
            $projects[$_subnetworkProjectId].networks[$_network.index].subnetworks[$_subnetwork.index].forwardingRules += $ipAddress_v4
        }
        
        foreach ($project in $projects.values) {
            $project.index = $allProjects.count
            
            foreach ($network in $project.networks) {
                foreach ($subnet in $network.subnetworks) {
                    $subnet.CalculateUtilization()
                }
            }
            [void]$allProjects.add($project)
        }

        return $allProjects
    }
    
    End {}    
}

# Explicit exports
$exports = @(
    "Get-ComputeSubnetworkUtilization"
)
Export-ModuleMember -Function $exports