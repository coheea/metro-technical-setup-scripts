param (
    [Parameter(Mandatory=$true)][string]$targetAssembly,
    [Parameter(Mandatory=$true)][string]$chefSourceLocation,
    [Parameter(Mandatory=$true)][string]$chefDropLocation,
    [Parameter(Mandatory=$true)][string]$finalFolder
 )

function Create-Manifest-File {
  param(
    [Parameter(Mandatory=$true)][string]$finalFolder,
    [Parameter(Mandatory=$true)][string]$packageName,
    [Parameter(Mandatory=$true)][string]$packageVersion,
    [Parameter(Mandatory=$true)][string]$packageHash
  )

  $manifestFile = ""
  $items = $finalFolder.Split("\")

  if ($items.Length -ge 4)
  {
    $build = $items[$items.Length-1]
    $branch = $items[$items.Length-3]
    $project = $items[$items.Length-4]
    $timestamp = Get-Date -Format o
    
    $manifestName = $packageName + ".json"

    $json = ("{{ " +
        """PackageName"": ""{0}"", " +
        """PackageVersion"": ""{1}"", " +
        """PackageHash"": ""{2}"", " +
        """BuildName"": ""{3}"", " +
        """BranchName"": ""{4}"", " +
        """Project"": ""{5}"", " +
        """Timestamp"": ""{6}"" " +
        "}}") -f $packageName, $packageVersion, $packageHash, $build, $branch, $project, $timestamp

    $manifestFile = Join-Path -Path $finalFolder -ChildPath $manifestName
    Set-Content -Path $manifestFile -Value $json -Force
  }

  $manifestFile
}

function Verify-FtpDirectory {
  param(
    [Parameter(Mandatory=$true)][string]$sourceuri,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password
  )

  $ftprequest = [System.Net.FtpWebRequest]::Create($sourceuri);
  $ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password)
          
  try
  {
    $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $response = $ftprequest.GetResponse();
    $response.Close();	
    return $true
  }
  catch
  {
    return $false
  }
}

function Create-FtpDirectory {
  param(
    [Parameter(Mandatory=$true)][string]$sourceuri,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password
  )

  Write-Host("Creating FTP directory $sourceuri")

  $ftprequest = [System.Net.FtpWebRequest]::Create($sourceuri);
  $ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password)
          
  try
  {
    $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
    $response = $ftprequest.GetResponse();
    Write-Host Directory Created, status $response.StatusDescription
    $response.Close();
  }
  catch
  {
    Write-Output("Error creating directory")
    Write-Error $_
  }
}

function Upload-Files {
  param(
    [Parameter(Mandatory=$true)][string]$targetUri,
    [Parameter(Mandatory=$true)][string]$sourceDir,
    [Parameter(Mandatory=$true)][string]$fileMask,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password
  )

  if ((Verify-FtpDirectory -sourceuri $targetUri -username $username -password $password) -ne $true)
  {
    Create-FtpDirectory -sourceuri $targetUri -username $username -password $password
  }

  $files = Get-ChildItem ("{0}\{1}"-f $sourceDir, $fileMask)
  foreach ($file in $files) 
  {
    $myUri = $targetUri + "/" + $file.Name
    "Uploading file {0} to {1}" -f $file, $myUri
    $uri = New-Object System.Uri($myUri) 
    $webclient.UploadFile($uri,$file)
  }	
}

if (Test-Path -path $targetAssembly)
{
  try
  {
    # The FileVersionInfo class is used for the exe because the VB6 apps don't like the Get-ChildItem objects
    $info = (Get-Command $targetAssembly).FileVersionInfo
    
    $version = $info.FileVersion.Trim()

    $token = "{version}"

    $files = Get-ChildItem ("{0}\*.rb" -f $chefSourceLocation)
    foreach ($file in $files) 
    {
      "Substituting token ""{0}"" in file {1} with value ""{2}""" -f $token, $file.Name, $version
      $fileContent = Get-Content $file -Raw
      $newFileContent = $fileContent -replace $token, $version.ToString().Trim()

      "Replacing content of file {0}" -f $file.FullName
      Set-Content -Path $file.FullName -Value $newFileContent -Force
    }

    $finalChefFolder = Join-Path -Path $finalFolder -ChildPath "chef"
    $pathExists = Test-Path -path $finalChefFolder
    If ($pathExists -eq $false)
    {
       $xPath = New-Item $finalChefFolder -Type Directory
    }

    "Copying recipe and template files from {0} to {1}" -f $chefSourceLocation, $finalChefFolder
    Copy-Item ("{0}\*.*rb" -f $chefSourceLocation) -Destination $finalChefFolder -Force
  
    $manifestFile = Create-Manifest-File `
      -finalFolder $finalFolder `
      -packageName (Split-Path -Path $info.FileName -Leaf) `
      -packageVersion $version `
      -packageHash (Get-FileHash $info.FileName -Algorithm SHA1).Hash

    #ftp server 
    $ftp = "ftp://10.5.112.17/" + $chefDropLocation
    $user = "metro-publisher" 
    $pass = "metPublisher"
 
    if ((Verify-FtpDirectory -sourceuri $ftp -username $user -password $pass) -ne $true)
    {
      Create-FtpDirectory -sourceuri $ftp -username $user -password $pass
    }
    
    $webclient = New-Object System.Net.WebClient 
    $webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)  

    # Upload the install package
    Upload-Files `
      -targetUri ($ftp + "/setup-files") `
      -sourceDir $finalFolder `
      -fileMask (Split-Path -Path $targetAssembly -Leaf) `
      -username $user `
      -password $pass

    # Upload the manifest file
    Upload-Files `
      -targetUri ($ftp + "/setup-files") `
      -sourceDir $finalFolder `
      -fileMask (Split-Path -Path $manifestFile -Leaf) `
      -username $user `
      -password $pass

    # Upload recipe files
    Upload-Files `
      -targetUri ($ftp + "/cookbooks/metropolis/recipes") `
      -sourceDir $chefSourceLocation `
      -fileMask "*.rb" `
      -username $user `
      -password $pass

    # Upload templates
    Upload-Files `
      -targetUri ($ftp + "/cookbooks/metropolis/templates") `
      -sourceDir $chefSourceLocation `
      -fileMask "*.erb" `
      -username $user `
      -password $pass

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