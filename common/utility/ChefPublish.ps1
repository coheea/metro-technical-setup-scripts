param (
    [Parameter(Mandatory=$true)][string]$targetAssembly,
	[Parameter(Mandatory=$true)][string]$chefSourceLocation,
	[Parameter(Mandatory=$true)][string]$chefDropLocation
 )

if (Test-Path -path $targetAssembly)
{
  try
  {
    $version = (Get-Command $targetAssembly).FileVersionInfo.FileVersion
    "Installer Version: {0}" -f $version
  
    $token = "{version}"

    $files = Get-ChildItem ("{0}\*.rb" -f $chefSourceLocation)
    foreach ($file in $files) 
    {
      "Substituting in file {0}: Token={1}, Version={2}" -f $file.Name, $token, $version
      $fileContent = Get-Content $file -Raw
      $newFileContent = $fileContent -replace $token, $version.ToString().Trim()
      Set-Content -Path ("{0}\cookbooks\metropolis\recipes\{1}" -f $chefDropLocation, $file.Name) -Value $newFileContent
    }	
    
    Copy-Item ("{0}\*.erb" -f $chefSourceLocation) -Destination ("{0}\cookbooks\metropolis\templates" -f $chefDropLocation)	
	Copy-Item $targetAssembly -Destination ("{0}\setup-files" -f , $chefDropLocation)	

    return 0
  }
  catch
  {
    "An exception occured while preparing the chef output"
	Write-Error $_
    return 2
  }
}
else
{
  "Installer file not found"
  return 1
}