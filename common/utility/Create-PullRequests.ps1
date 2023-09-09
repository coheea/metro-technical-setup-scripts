param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $repository,
    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $branch,
    [Parameter(Mandatory = $true, Position = 3)]
    [string]
    $buildName,
    [Parameter(Mandatory = $false, Position = 4)]
    [string]
    $approvers,
    [Parameter(Mandatory = $true, Position = 5)]
    [string]
    $token
)

Function Convert-YAMLFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $catalogFile
    )

    [string[]]$fileContent = Get-Content $catalogFile
    $content = ''
    foreach ($line in $fileContent) { $content = $content + "`n" + $line }
    $yaml = ConvertFrom-YAML $content -Ordered

    return $yaml
}

Function Get-APIData {
    Param(
        [string]$Uri,
        [hashtable]$Headers
    )

    $Result = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Headers

    return $Result
}

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

$RepoName = ($repository -Split "/")[-1]
$PullPayload = @{
    "title" = "Merge $($buildName) Changes to Main";
    "body" = "Merge $($buildName) Changes to Main create new Pre Release Package";
    "head" = "$branch";
    "base" = "main"
}

$PullRequestDetails = Get-APIData -Uri "https://api.github.com/repos/ebetsystems/$RepoName/pulls?head=$branch&state=open" -Headers @{"Authorization" = "Bearer $token"; "X-GitHub-Api-Version" = "2022-11-28"; "Accept" = "application/vnd.github+json"}

if($PullRequestDetails.Count -eq 0){
    $CreatePullRequest = Post-APIData -Uri "https://api.github.com/repos/ebetsystems/$RepoName/pulls" -Headers @{"Authorization" = "Bearer $token"; "X-GitHub-Api-Version" = "2022-11-28"; "Accept" = "application/vnd.github+json"} -Payload ($PullPayload | ConvertTo-Json)

    if($approvers){
        if($approvers -match ","){
            $approverList = @("$approvers")
        } else{
            $approverList = $approvers -Split ","
        }
        $ReviewersPayload = @{
            "team_reviewers" = $approverList
        }
        $AddReviewers = Post-APIData -Uri "https://api.github.com/repos/ebetsystems/$RepoName/pulls/$($CreatePullRequest.number)/requested_reviewers" -Headers @{"Authorization" = "Bearer $token"; "X-GitHub-Api-Version" = "2022-11-28"; "Accept" = "application/vnd.github+json"} -Payload ($ReviewersPayload | ConvertTo-Json)    
    }
} else {
    Write-Host "Pull Request already exists for feature branch $branch"
}