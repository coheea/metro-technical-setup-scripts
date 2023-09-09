param (
    [Parameter(Mandatory = $true)]
    [string]
    $ParentDirectory,
    [Parameter(Mandatory = $true)]
    [string]
    $AppName,
    [Parameter(Mandatory = $true)]
    [string]
    $AppId,
    [Parameter(Mandatory = $true)]
    [string]
    $CatalogFile,
    [Parameter(Mandatory = $true)]
    [string]
    $Token
)

#Function used to convert YML file to PSObject
Function Convert-YAMLFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $catalogFile
    )

    [string[]]$fileContent = Get-Content $catalogFile
    $content = ''
    foreach ($line in $fileContent) { $content = $content + "`n" + $line }
    $yaml = ConvertFrom-YAML $content -Ordered

    return $yaml
}


# WriteYml function that writes the YML content to a file
function Write-YmlFile {
    param (
        $FileName,
        $Content
    )
	#Serialize a PowerShell object to string
    $result = ConvertTo-YAML $Content
    #write to a file
    Set-Content -Path $FileName -Value $result
}

#Function used to perform GET API commands
Function Get-APIData {
    Param(
        [string]$Uri,
        [hashtable]$Headers
    )

    $Result = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Headers

    return $Result
}

#Install YML module if not installed already
$YamlModule = Get-Module -Name powershell-yaml
if(!$YamlModule){
    Install-Module powershell-yaml -Force
}


$root = Convert-YAMLFile -catalogFile $CatalogFile
$Packages = $root.Catalog.Packages

#Loop through packages
foreach ($PackageName in $Packages.Keys){
    #Get all non prod environments and delete their values
    $NonProdEnvironments = @()
    foreach($Environment in $Packages[$PackageName]["Environments"].Keys){
        if($Environment -ne "prod"){
            $NonProdEnvironments += $Environment
        }
    }
    foreach($NonProdEnvironment in $NonProdEnvironments){
        $Packages[$PackageName]["Environments"].Remove($NonProdEnvironment)
    }
}

#Write modified YML file
Write-YmlFile $CatalogFile $root

#Push changes to the YML file to the metro-pipeline repository
cd $ParentDirectory
git config user.name "$AppName[bot]"
git config user.email "$AppId+$AppName[bot]@users.noreply.github.com"
$DetatchedHead = git rev-parse --abbrev-ref --symbolic-full-name HEAD
if($DetatchedHead -eq "HEAD"){
    git remote add PipelineOrigin "https://$($AppName):$Token@github.com/ebetsystems/metro-pipeline.git"
    git branch temp
    git checkout temp
    git add $CatalogFile
    git commit -m "Update catalog for $NextEnvironment"
    git branch -f main temp
    git checkout main
    git branch -d temp
    git push PipelineOrigin main
} else{
    try{
        git remote add PipelineOrigin "https://$($AppName):$Token@github.com/ebetsystems/metro-pipeline.git"
        git add $CatalogFile
        git commit -m "Update catalog for $NextEnvironment"
        git push PipelineOrigin "main"
    } catch{
        git add $CatalogFile
        git commit -m "Update catalog for $NextEnvironment"
        git push
    }
}


