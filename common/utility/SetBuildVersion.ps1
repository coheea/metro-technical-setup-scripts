Param
(
    [Parameter(Mandatory=$true)] [string] $targetFile,
	[Parameter()]                [string] $buildNumber = '',
	[Parameter()]                [string] $revert = '0'
)

if ($revert -eq '0' -and $buildNumber -eq '')
{
    "ERROR: Invalid revert and buildNumber parameter combination"
	return
}

$backupFile = "{0}.orig" -f $targetFile

if ($revert -eq '1')
{
    "Removing the updated assembly version file: TargetFile=$targetFile"
    Remove-Item -Path $targetFile -Force
}
elseif (Test-Path -Path $backupFile)
{  
    "Removing the previous assembly version backup: BackupFile=$backupFile"
    Remove-Item -Path $backupFile -Force
}

if ($revert -eq '1')
{
    "Restoring the original assembly version file: BackupFile=$backupFile, TargetFile=$targetFile"
    Rename-Item -Path $backupFile -NewName $targetFile -Force
}
else
{
    "Updating informational version in file $targetFile with build number $buildNumber"
    Rename-Item -Path $targetFile -NewName $backupFile -Force
	((Get-Content -path $backupFile -Raw) -replace '\$BuildNumber\$', $buildNumber) | Set-Content -Path $targetFile
}
