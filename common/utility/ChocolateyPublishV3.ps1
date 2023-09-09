param (
    [Parameter(Mandatory=$true)][string]  $targetAssembly,
    [Parameter(Mandatory=$true)][string]  $installerMask,
	[Parameter(Mandatory=$true)][string]  $dropLocation,
	[Parameter(Mandatory=$true)][string]  $buildNumber,
	[Parameter(Mandatory=$false)][string] $appType
 )

if (Test-Path -path $targetAssembly)
{
  "Loading the target assembly: {0}" -f $targetAssembly
 
  #$assembly = [System.Reflection.Assembly]::LoadFrom($targetAssembly)
  #$version = "{0}" -f $assembly.GetName().Version

  $version = (Get-Command $targetAssembly).FileVersionInfo.FileVersion
  
  if ($buildNumber -ne "")
  {
    $build = $buildNumber.Split('_')
	$build = $build[$build.Length-1]
	$buildbits = $build.Split('.')
	$build = $buildbits[0].Substring($buildbits[0].Length-6) + $buildbits[1].PadLeft(2,'0')
	
    $part = $version.Split('.')
	
	if ($appType -eq '1') 
	{
	  #app type 1 = vb6
	  $version = $part[0] + '.' + $part[1] + '.' + $part[3] + '.' + $build
	}
	else
	{
	  #otherwise .net
	  $version = $part[0] + '.' + $part[1] + '.' + $part[2] + '.' + $build
	}
  }
  
  "Assembly Version: {0}" -f $version
  
  "Searching for installer using mask = {0}" -f $installerMask
  $installer = (Get-ChildItem -Path $installerMask -Force -Recurse -File | Select-Object -First 1).Name

  if ($installer -ne "")
  {
    try
    {
      if (Test-Path -path .\tools) 
      { 
        "Removing the existing tools folder"
        Remove-Item -path .\tools -recurse 
      }

      if (Test-Path -path *.nupkg) 
      {
        "Removing existing packages"
        Remove-Item -path "*.nupkg" 
      }
    
      "Creating the tools folder"
      $null = New-Item -Path "." -Name "tools" -ItemType "directory"
      
      "Copying {0} to the tools folder" -f $installer
      Copy-Item (".\output\{0}" -f $installer) -Destination .\tools

      "Creating the chocolateyinstall.ps1 file"
      ((Get-Content -path .\chocolateyinstall.ps1 -Raw) -replace '{SetupFileName}', $installer) | Set-Content -Path ".\tools\chocolateyinstall.ps1"

      "Creating the Chocolatey package"
      choco pack --version $version --limitoutput
      if ($?)
      {
	    "Copying the nupkg file to the output folder"
	    Copy-Item ("*.nupkg") -Destination .\output
        
		"Publishing the package to {0}" -f $dropLocation
        choco push --source=$dropLocation
        if ($?)
        {
          "Package published successfully"
        }
      }

      return 0
    }
    catch
    {
        "An exception occured while preparing the chocolatey package"
        return 2
    }
  }
}
else
{
  "Installer file not found"
  return 1
}