param (
    [Parameter(Mandatory=$true)][string]$targetAssembly,
    [Parameter(Mandatory=$true)][string]$installerMask,
	[Parameter(Mandatory=$true)][string]$dropLocation
 )

if (Test-Path -path $targetAssembly)
{
  "Loading the target assembly: {0}" -f $targetAssembly
 
  #$assembly = [System.Reflection.Assembly]::LoadFrom($targetAssembly)
  #$version = "{0}" -f $assembly.GetName().Version

  $version = (Get-Command $targetAssembly).FileVersionInfo.FileVersion
  "Assembly Version: {0}" -f $version
  
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
      choco pack --version $version
      if ($?)
      {
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