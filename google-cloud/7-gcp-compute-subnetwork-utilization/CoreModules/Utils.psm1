Import-Module -Name .\CoreModules\GCP.psm1

function Set-Environment {
    param (
        [string]$CurrentWorkSpace
    )
    Set-Variable -Name WorkSpacePath -value ("./Workspaces/$CurrentWorkSpace/Artifacts") -Scope Global
    if (Test-Path $Global:WorkSpacePath) {
        Set-GlobalSettings
    }
    else {
        New-Item -Path $Global:WorkSpacePath -ItemType Directory -Force -Confirm:$false | Out-Null
        Set-GlobalSettings
    }

}
function Set-GlobalSettings {
    param (
        
    )
    class Settings {
        [int]$Refresh
        [string[]]$AuthorizedDomains
        Settings() {
            $this.Refresh = 12
            $this.AuthorizedDomains = @($Global:DefaultDomainName)
        }
    }
    if (Test-Path "$Global:WorkSpacePath/settings.json") {
        Set-Variable -Name Settings -value (Get-Content "$Global:WorkSpacePath/settings.json" | ConvertFrom-Json) -Scope Global
    }
    else {
        [Settings]::new() | ConvertTo-Json -Depth 10 | Out-File "$Global:WorkSpacePath/settings.json"
        Set-Variable -Name Settings -value (Get-Content "$Global:WorkSpacePath/settings.json" | ConvertFrom-Json) -Scope Global
    }
    
}
function Test-ArtifactExpiration {
    param (
        [string]$Name
    )
    
    try {
        $artifact = Get-Item "$Global:WorkSpacePath/$Name" -ErrorAction Stop
        if ((($artifact.LastWriteTime - [datetime]::Now) / -1).Hours -lt $Global:settings.Refresh) {
            return $false
        }
        else {
            return $true
        } 
    }
    catch {
        return $true
    }
    
    
}
function Import-Artifact {
    param (
        [string]$Name
    )
    try {
        Import-Clixml "$Global:WorkSpacePath/$Name" -ErrorAction Stop

    }
    catch {
        Write-Host -ForegroundColor Red "[+] Could not find artifact to load."
        Write-Host -ForegroundColor Yellow "[+] Make sure you run collection for $($Name.split(".")[0])"
    }
}
function Export-Artifact {
    param (
        [string]$Name,
        [object]$Artifacts
    )
    return Export-Clixml "$Global:WorkSpacePath/$Name" -InputObject $Artifacts -Force -Confirm:$false
}
function Remove-Artifact {
    param (
        [string]$Name
    )
    try {
        Remove-Item "$Global:WorkSpacePath/$Name" -Force -Confirm:$false -ErrorAction Stop
    }
    catch {}
    
}
function Test-ArtifactDependencies {
    param (
        [string[]]$DependencyNames
    )
    class Result {
        [bool]$Check
        [string]$Message
    }
    foreach ($Name in $DependencyNames) {
        if((Test-Path "$Global:WorkSpacePath/$Name.xml") -eq $false) {
            throw "Make sure you run collection for each artifact $($DependencyNames -join ',')"
        }
    }
}
function Update-WorkspaceSettings {
    param (
        
    )
    Set-GlobalSettings
    
}
function New-FolderLookup {
    <#
    .SYNOPSIS
    Creates in memory key value lookup where key is folderid and value is folder display name
    
    .DESCRIPTION
    Polling api every time for folder names is expensive this function creates in memory key value lookup where key is folderid and value is folder display name

    
    .PARAMETER OrganizationId
    GCP Organization ID 
    
    .EXAMPLE
    $folders = New-FolderLookup -OrganizationId "123456789"
    
    .NOTES
    Access folder name: $folders["1097427954669"]  
    #>
    param (
        [string]$OrganizationId
    )
    $lookup = @{}
    $folders = Invoke-GCPAPI -Url "https://cloudasset.googleapis.com/v1/organizations/$($OrganizationId):searchAllResources?&assetTypes=cloudresourcemanager.googleapis.com.Folder&pageSize=500&query=state:ACTIVE" `
        -ThrottleLimit 500 `
        -ResponseProperty "results" `
        -GET
        foreach ($folder in $folders) {
            [void]$lookup.Add($folder.name.split("/")[-1], $folder.displayName)
        }
        $lookup
}
function New-ProjectLookup {
    <#
    .SYNOPSIS
    Creates in memory key value lookup where key is projectid and value is project display name
    
    .DESCRIPTION
    Polling api every time for project names is expensive this function creates in memory key value lookup where key is projectid and value is project display name

    
    .PARAMETER OrganizationId
    GCP Organization ID 
    
    .EXAMPLE
    $projects = New-ProjectLookup -OrganizationId "123456789"
    
    .NOTES
    Access project name: $projects["1097427954669"]  
    #>
    param (
        [string]$OrganizationId,
        [switch]$NameToNumber
    )
    $lookup = @{}
    $projects = Invoke-GCPAPI -Url "https://cloudasset.googleapis.com/v1/organizations/$($OrganizationId):searchAllResources?&assetTypes=cloudresourcemanager.googleapis.com.Project&pageSize=500&query=state:ACTIVE" `
         -ThrottleLimit 500 `
         -ResponseProperty "results" `
         -GET

        if ($NameToNumber.IsPresent) {
            foreach ($project in $projects) {
                [void]$lookup.Add($project.name.split("/")[-1], $project.project.split("/")[1])
            }
            $lookup
            $artifactName = "ProjectsNameToNumber.xml"
            Export-Artifact -Name $artifactName -Artifacts $lookup
        }
        else {
            foreach ($project in $projects) {
                [void]$lookup.Add($project.project.split("/")[1], $project.name.split("/")[-1])
            }
            $lookup
            $artifactName = "Projects.xml"
            Export-Artifact -Name $artifactName -Artifacts $lookup
        }
        
}
function New-GCPSession {
    $header = @{
        "Authorization" = "Bearer $((gcloud auth print-access-token --format=json | ConvertFrom-Json | Select-Object token).token)"
    }
    Set-Variable -Name AuthHeader -Value $header -Scope Global
    $orgs = (Invoke-RestMethod -Uri "https://cloudresourcemanager.googleapis.com/v1/organizations:search" -Method Post -Headers $Global:AuthHeader).organizations
    $orglookup = @{}
    $counter = 1
    foreach ($org in $orgs) {
        $orglookup.Add($org.displayName, $counter)
        $counter ++ 
    }
    $selectedOrg = ""
    $domainName = ""
    while ($true) {
        Write-Host -ForegroundColor Green "[+] Select a organization: `n"
        for ($i = 1 ; $i -lt $orgs.Count + 1; $i++) {
            Write-Host -ForegroundColor Green "[$i] " -NoNewline
            Write-Host "$($orgs[$i -1].displayName)"
        }
        Write-Host
        $selection = Read-Host
        try {
            $orglookup.ContainsKey($orgs[$selection - 1].displayName)
        }
        catch {
            Clear-Host
            Write-Host -ForegroundColor Red "`nProvide a proper selection"
            Start-Sleep 3
            Clear-Host
            continue
        }
        
        Clear-Host
        $confirm = @"
        Confirm selection y/n

Selected org: $($orgs[$selection - 1].displayName)
"@
        $confirm = Read-Host -Prompt $confirm
        if ($confirm -eq "y") {
            $selectedOrg = $orgs[$selection - 1].name.Split("/")[1]
            $domainName = $orgs[$selection - 1].displayName
            break
        }
        if ($confirm -eq "n") {
            Clear-Host
            continue
        }
        Clear-Host
        
    }
    Set-Variable -Name DefaultDomainName -Value $domainName -Scope Global
    Set-Environment -CurrentWorkSpace ($Global:DefaultDomainName.split(".")[0])
    Set-Variable -Name Folders -Value (New-FolderLookup -OrganizationId $selectedOrg) -Scope Global
    Set-Variable -Name Projects -Value (New-ProjectLookup -OrganizationId $selectedOrg) -Scope Global
    Set-Variable -Name ProjectsNameToNumber -Value (New-ProjectLookup -OrganizationId $selectedOrg -NameToNumber) -Scope Global
    Set-Variable -Name OrgId -Value $selectedOrg -Scope Global
}

function New-EncodedCommandFromFile {
    param (
        [string]$RelativePathToMainModule
    )
    $script = [System.IO.File]::ReadAllText($RelativePathToMainModule, [System.Text.Encoding]::UTF8);
    $ByteArray = [System.Text.Encoding]::Unicode.GetBytes($script)
    $encodedCommand = [Convert]::ToBase64String($ByteArray);
    $encodedCommand
}

# Explicit exports
$exports = @(
    "Set-Environment",
    "Test-ArtifactExpiration",
    "Import-Artifact",
    "Export-Artifact",
    "Remove-Artifact",
    "New-ArtifactCollectionJob",
    "Get-RunningCollectionJobs",
    "Update-WorkspaceSettings",
    "Test-ArtifactDependencies",
    "New-FolderLookup",
    "New-ProjectLookup",
    "New-GCPSession",
    "New-EncodedCommandFromFile",
    "Get-GCPFolderName"
)

Export-ModuleMember -Function $exports