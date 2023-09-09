param (
  [Parameter(Mandatory=$true)][string]$targetAssembly,
	[Parameter(Mandatory=$true)][string]$chefSourceLocation,
	[Parameter(Mandatory=$true)][string]$chefDropLocation
 )

if (Test-Path -path $targetAssembly)
{
  try
  {
    #ftp server 
    $ftp = "ftp://10.5.112.17/" + $chefDropLocation
    $user = "metro-publisher" 
    $pass = "metPublisher"
 
    $webclient = New-Object System.Net.WebClient 
    $webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)  

    # The FileVersionInfo class is used for the exe because the VB6 apps don't like the Get-ChildItem objects
    $info = (Get-Command $targetAssembly).FileVersionInfo
    $version = $info.FileVersion.Trim()
    $fileName = [System.IO.Path]::GetFileName($targetAssembly)   
    $myUri = $ftp + "/setup-files/" +  $fileName

    "Uploading file {0} ({1}) to {2}" -f $targetAssembly, $version, $myUri

    $uri = New-Object System.Uri($myUri)
    $webclient.UploadFile($uri,$targetAssembly)

    $token = "{version}"

    $files = Get-ChildItem ("{0}\*.rb" -f $chefSourceLocation)
    foreach ($file in $files) 
    {
      "Substituting in file {0}: Token={1}, Version={2}" -f $file.Name, $token, $version
      $fileContent = Get-Content $file -Raw
      $newFileContent = $fileContent -replace $token, $version.ToString().Trim()
      $newFile = $file.FullName + ".new"

      Set-Content -Path ($newFile) -Value $newFileContent

      $myUri = $ftp + "/cookbooks/metropolis/recipes/" + $file.Name
      "Uploading file {0} to {1}" -f $newFile, $myUri

      $uri = New-Object System.Uri($myUri) 
      $webclient.UploadFile($uri,$newFile)
    }	
    
	#
	# This will be re-enabled once config files are updated with working placeholders
	#
    #$files = Get-ChildItem ("{0}\*.erb" -f $chefSourceLocation)
    #foreach ($file in $files) 
    #{
    #  $myUri = $ftp + "/cookbooks/metropolis/templates/" + $file.Name
    #  "Uploading file {0} to {1}" -f $file.FullName, $myUri

    #  $uri = New-Object System.Uri($myUri)
    #  $webclient.UploadFile($uri,$file.FullName)
    #}	

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