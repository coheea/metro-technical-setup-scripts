param (
    [Parameter(Mandatory = $true)]
    [string]
    $Repository,
    [Parameter(Mandatory = $true)]
    [string]
    $TagName
)

#Check if GitHub Release exists already
$ReleaseExists = gh release view $TagName --repo $Repository

#Sets environment variable ReleaseExists
if($ReleaseExists -notmatch "release not found"){
    echo ("ReleaseExists=" + "true") >> $env:GITHUB_ENV
} else {
    echo ("ReleaseExists=" + "false") >> $env:GITHUB_ENV
}

#Required for GitHub Action not to error our if release not found
if ($lastexitcode -lt 8) { $global:lastexitcode = 0 }