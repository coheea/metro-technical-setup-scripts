param (
    [Parameter(Mandatory = $true)]
    [string]
    $Directory,
    [Parameter(Mandatory = $true)]
    [string]
    $DestinationPath,
    [Parameter(Mandatory = $true)]
    [string]
    $PackageName,
    [Parameter(Mandatory = $true)]
    [string]
    $TagName,
    [Parameter(Mandatory = $true)]
    [string]
    $Repository
)

#Create new folder based on the value passed in for DestinationPath
New-Item -Path "$DestinationPath" -ItemType Directory -ErrorAction SilentlyContinue
#Compress the Directory specified and save it in the folder above
Compress-Archive -Path "$Directory" -DestinationPath "$DestinationPath\$PackageName.zip"
#upload newly compressed package as a GitHub Release artifact on the repository and release specified
gh release upload $TagName "$DestinationPath\$PackageName.zip" --clobber --repo "https://github.com/$Repository"
#Perform cleanup and delete compressed file
Remove-Item "$DestinationPath\$PackageName.zip" -Force