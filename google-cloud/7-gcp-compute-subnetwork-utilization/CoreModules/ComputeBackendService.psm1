Import-Module -Name .\CoreModules\GCP.psm1
Import-Module -Name .\CoreModules\Utils.psm1

# Collection function
function Get-ComputeBackendServices {
    param (
        [string]$OrganizationId = $Global:OrgId,
        [switch]$ForceArtifactFetch
    )
    $artifactName = "ComputeBackendServices.xml"
    $jobName = "ComputeBackendServices"
    $jobs = Get-Job -State "Running" | Where-Object {$_.Name -eq $jobName}
    if ($jobs.Count -gt 0) {
        Write-Host "[+] Still collecting all Compute BackendServices" -ForegroundColor Green
        break
    }
    
    if ($ForceArtifactFetch.IsPresent) {
        Remove-Artifact -Name $artifactName
    }

    if ((Test-ArtifactExpiration -Name $artifactName) -eq $false) {
        return Import-Artifact -Name $artifactName
    }
    else {
        # Create thread script block to pass to Start-ThreadJob
        $collectionJob = {
            param(
                $OrganizationId,
                $ArtifactName,
                $AuthHeaders,
                $CurrentWorkSpace
            )
            # This thread job / scriptblock is off main thread so we need to import module code into that runspace
            Import-Module -Name .\CoreModules\Utils.psm1
            Import-Module -Name .\CoreModules\GCP.psm1

            # Need to inject globals into runspace
            Set-Variable -Name WorkSpacePath -value $CurrentWorkSpace -Scope Global
            Set-Variable -Name AuthHeader -Value $AuthHeaders -Scope Global
            $allComputeBackendServices = Invoke-GCPAPI -Url "https://cloudasset.googleapis.com/v1/organizations/$($OrganizationId)/assets?pageSize=500" `
                -ThrottleLimit 500 `
                -ResponseProperty "assets" `
                -POST `
                -AssetTypes "compute.googleapis.com/BackendService"

            # Let's get all the good stuff by calling describe method
            $response = $allComputeBackendServices | ForEach-Object -Parallel {
                # This thread job / scriptblock is off main thread so we need to import modules inject vars
                Set-Variable -Name AuthHeader -Value $using:AuthHeaders -Scope Global
                Import-Module -Name .\CoreModules\GCP.psm1

                $_name = $_.name.Split("/")
                if ($_name[5] -eq "global") {
                    $url = "https://compute.googleapis.com/compute/v1/projects/$($_name[4])/global/backendServices/$($_name[-1])"
                } else {
                    $url = "https://compute.googleapis.com/compute/v1/projects/$($_name[4])/regions/$($_name[6])/backendServices/$($_name[-1])"
                }

                Invoke-GCPAPI -Url $url `
                        -ThrottleLimit 1 `
                        -NoResponseProperty `
                        -GET
                } -ThrottleLimit 500
            
            # Exporting our artifact out to disk from within our thread job
            Export-Artifact -Name $artifactName -Artifacts $response
        }
        
        # Thread job to get collection operation off main thread and not block
        # Always remember to take in params for variables that need to be passed through to runspaces
        # Always remember the cleanest way to get code into runspace is via import-Module 
        $job = Start-ThreadJob -ScriptBlock $collectionJob `
            -ArgumentList @($OrganizationId, $artifactName, $Global:AuthHeader, $Global:WorkSpacePath) `
            -Name $jobName
        Write-Host -ForegroundColor Yellow "[+] Artifact collection job started for $($job.Name) with Id: $($job.Id). You can check status by calling:"
        Write-Host -ForegroundColor Green "Get-Job -Id $($job.Id)"
    }
}

# Explicit exports
$exports = @(
    "Get-ComputeBackendServices"
)
Export-ModuleMember -Function $exports