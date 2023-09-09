param (
    [Parameter(Mandatory=$true)][string]$finalFolder,  
    [Parameter(Mandatory=$true)][string]$projectName,
    [Parameter(Mandatory=$true)][string]$branchName,
    [Parameter(Mandatory=$true)][string]$buildDefinition,
    [Parameter(Mandatory=$true)][string]$buildName
)

"Attempting to publish $finalFolder to Artifactory"
$rc = 1
$fileName = "$buildName.zip"
$tempPath = $env:TEMP

$url = "https://artifactory.tattsgroup.com/artifactory/gaming-metro-dev/$projectName/$branchName/$buildDefinition/$fileName"

try
{
    $pathExists = Test-Path -path $tempPath
    If ($pathExists -eq $false)
    {
       $xPath = New-Item $tempPath -Type Directory | Out-Null
    }
	
    "Compressing folder $finalFolder to $fileName"
    Compress-Archive -Path "$finalFolder\*" -DestinationPath "$tempPath\$fileName" -Force
    
    "Calculating Checksum values"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    #$headers.Add("X-Checksum-MD5", $(Get-FileHash -Algorithm MD5 "$tempPath\$fileName").Hash)
    $headers.Add("X-Checksum-SHA1", $(Get-FileHash -Algorithm SHA1 "$tempPath\$fileName").Hash)

    "Uploading to $url"
    $PWord = ConvertTo-SecureString -String "TabTabTab01" -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "svcBuildSystem", $PWord
    Invoke-RestMethod -uri $url -Method Put -InFile "$tempPath\$fileName" -Credential $cred -ContentType "multipart/form-data" -Headers $headers
	
	Remove-Item "$tempPath\$fileName"
    $rc = 0
}
catch 
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    
	"Error publishing to Artifactory: Item=$FailedItem; Message=$ErrorMessage"
}
exit $rc