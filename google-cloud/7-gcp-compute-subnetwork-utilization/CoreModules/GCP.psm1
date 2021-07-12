function Invoke-GCPAPI {
    param(
        [string]$Url,
        [string]$AssetTypes,
        [string]$ResponseProperty,
        [int]$ThrottleLimit,
        [switch]$NoPageToken,
        [switch]$NoResponseProperty,
        [switch]$GET,
        [switch]$POST
    )
    if ($GET.IsPresent) {
        if ($NoPageToken.IsPresent) {
            (Invoke-RestMethod -uri $url -Headers $Global:AuthHeader).$ResponseProperty
        }
        if ($NoResponseProperty.IsPresent) {
            Invoke-RestMethod -uri $url -Headers $Global:AuthHeader
        }
        else {
            $response = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
            $pageToken = ""
            do {
                $r = Invoke-RestMethod -uri "$($url)&pageToken=$($pageToken)" -Headers $Global:AuthHeader
                $pageToken = $r.nextPageToken
                $r.$ResponseProperty | ForEach-Object -Parallel {
                    $objectBag = $using:response
                    [void]$objectBag.Add($_)
                } -ThrottleLimit $ThrottleLimit
                
            } until ($null -eq $r.nextPageToken)
            $response.ToArray()
        }
    } elseif ($POST.IsPresent) {
        $headers = $Global:AuthHeader.Clone()
        [void]$headers.add('Content-Type', 'application/json')
        [void]$headers.add('X-HTTP-Method-Override', 'GET')
        $body=@{
            assetTypes = $AssetTypes
            pageToken = ""
        }
        $bodyJSON=$body|ConvertTo-JSON
        if ($NoPageToken.IsPresent) {
            (Invoke-RestMethod -Method 'Post' -Body $bodyJSON -uri $url -Headers $headers).$ResponseProperty
        }
        if ($NoResponseProperty.IsPresent) {
            Invoke-RestMethod -Method 'Post' -Body $bodyJSON -uri $url -Headers $headers
        }
        else {
            $response = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
            do {
                $r = Invoke-RestMethod -Method 'Post' -Body $bodyJSON -uri "$($url)" -Headers $headers
                $body.pageToken = $r.nextPageToken
                $bodyJSON=$body|ConvertTo-JSON
                $r.$ResponseProperty | ForEach-Object -Parallel {
                    $objectBag = $using:response
                    [void]$objectBag.Add($_)
                } -ThrottleLimit $ThrottleLimit
                
            } until ($null -eq $r.nextPageToken)
            $response.ToArray()
        }

    }
}

# Explicit exports
$exports = @(
    "Invoke-GCPAPI"
)

Export-ModuleMember -Function $exports