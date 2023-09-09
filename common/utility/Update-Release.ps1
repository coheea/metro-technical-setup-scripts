param(
    [Parameter(Mandatory = $true)]
    [string]
    $PRNumber,
    [Parameter(Mandatory = $true)]
    [string]
    $Repository,
    [Parameter(Mandatory = $true)]
    [string]
    $Token
)

#Function used to perform GET API operations
Function Get-APIData {
    Param(
        [string]$Uri,
        [hashtable]$Headers
    )

    $Result = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Headers

    return $Result
}

#Function used to perform POST API operations
Function Post-APIData {
    Param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Payload
    )

    if($Payload){
        $Result = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers -Body $Payload
    } else {
        $Result = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers
    }

    return $Result
}

#Function used to perform PUT API operations
Function Put-APIData {
    Param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Payload
    )

    $Result = Invoke-RestMethod -Uri $Uri -Method PATCH -Headers $Headers -Body $Payload

    return $Result
}


$RepoName = ($Repository -Split "/")[1]
$PullRequestDetails = Get-APIData -Uri "https://api.github.com/repos/ebetsystems/$RepoName/pulls/$PRNumber" -Headers @{"Authorization" = "Bearer $Token"; "X-GitHub-Api-Version" = "2022-11-28"; "Accept" = "application/vnd.github+json"}
$ReleaseBody = ($PullRequestDetails.Body -Split "`n")[1]
$ReleaseJSONBody = ConvertFrom-JSON $ReleaseBody

$ReleaseDetail = Get-APIData -Uri "https://api.github.com/repos/ebetsystems/$RepoName/releases/tags/$($ReleaseJSONBody.Tag)" -Headers @{"Authorization" = "Bearer $Token"; "X-GitHub-Api-Version" = "2022-11-28"; "Accept" = "application/vnd.github+json"}
$BuildName = ($ReleaseDetail.name -Split " ")[1]
$TagName = "main-$BuildName"

$ReleasePayload = @{
    "tag_name" = "$TagName";
    "draft" = $false;
    "prerelease" = $true
}

$UpdateRelease = Put-APIData -Uri "https://api.github.com/repos/ebetsystems/$RepoName/releases/$($ReleaseDetail.id)" -Headers @{"Authorization" = "Bearer $Token"; "X-GitHub-Api-Version" = "2022-11-28"; "Accept" = "application/vnd.github+json"} -Payload ($ReleasePayload | ConvertTo-Json)