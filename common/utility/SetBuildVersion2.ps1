Param
(
    [Parameter(Mandatory=$true)] [string] $targetFile,
	$params = @{},
	$revert = '0',
	$tokenIdentifier  = '$'
)

$backupFile = "{0}.orig" -f $targetFile

if ($revert -eq '1')
{
    "Removing the updated file"
    Remove-Item -Path $targetFile -Force
}
elseif (Test-Path -Path $backupFile)
{  
    "Removing the previous backup file"
    Remove-Item -Path $backupFile -Force
}

if ($revert -eq '1')
{
    "Restoring the original file"
    Rename-Item -Path $backupFile -NewName $targetFile -Force
}
else
{
    "Renaming $targetFile to $backupFile"
    Rename-Item -Path $targetFile -NewName $backupFile -Force

    "Updating tokens in $targetFile"

	$file = Get-Content $backupFile -Raw

    foreach ($e in $params.Keys) {
        $token = "\" + $tokenIdentifier + $e + "\" + $tokenIdentifier
		"$token = $params.$e"
        $file = $file -replace $token, $params.$e
    }

    Set-Content -Path $targetFile -Value $file
}
