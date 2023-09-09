if ($args.Length -ne 3)
{
  Write-Output 'Error: Insufficient arguments supplied.'
  Write-Output 'Usage: powershell nuget.pack.ps1 <Assembly Path> <Nuspec Template> <Nuspec Config>'
}
else
{
  $assembly = $args[0]
  $nuspec   = $args[1]
  $config   = $args[2]

  #$assembly = '.\binaries\M1.Core.Shared.dll'
  if (!(Test-Path -Path $assembly))
  {
    Write-Output "Assembly file not found: $assembly"
    return
  }

  #$nuspec   = 'my.nuspec'
  if (!(Test-Path -Path $nuspec))
  {
    Write-Output "Nuspec template file not found: $nuspec"
    return
  }

  #$config   = 'D:\setup-scripts\common\utility\nuspec.config'
  #$config   = ''
  if ((-not [String]::IsNullOrEmpty($config)) -and !(Test-Path -Path $config))
  {
    Write-Host "Nuspec config file not found: $config"
    return
  }

  Write-Host "Deleting any existing packages and the target _.nuspec file from the build folder"
  del *.nupkg
  del _.nuspec

  Write-Host "Loading the assembly version"
  $filever = (Get-Command $assembly).FileVersionInfo.FileVersion

  Write-Host "Substititing the {version} placeholder in the nuspec file with the assembly version $filever"
  (Get-Content -path $nuspec -Raw) -replace '{version}', $filever > _.nuspec

  D:\setup-scripts\common\utility\nuget pack _.nuspec

  Write-Host "Reading the name of the new package from disk"
  $package = (Get-ChildItem -Path .\*.nupkg -File | Select-Object -First 1).Name
  Write-Host "Package Name: $package"

  if ([String]::IsNullOrEmpty($config))
  {
    Write-Host 'Pushing the package using the default config'
    D:\setup-scripts\common\utility\nuget push $package
  }
  else
  {
    Write-Host "Pushing the package using config file $config"
    D:\setup-scripts\common\utility\nuget push $package -ConfigFile $config
  }
}