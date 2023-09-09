param (
    [Parameter(Mandatory = $true)]
    [string]
    $ParentDirectory,
    [Parameter(Mandatory = $false)]
    [string]
    $Repository,
    [Parameter(Mandatory = $false)]
    [string]
    $PackageName,
    [Parameter(Mandatory = $false)]
    [string]
    $PackageSubfolder,
    [Parameter(Mandatory = $true)]
    [string]
    $AppName,
    [Parameter(Mandatory = $true)]
    [string]
    $AppId,
    [Parameter(Mandatory = $true)]
    [string]
    $Environment,
    [Parameter(Mandatory = $false)]
    [string]
    $NextEnvironment,
    [Parameter(Mandatory = $false)]
    [string]
    $Tag,
    [Parameter(Mandatory = $true)]
    [string]
    $CatalogFile,
    [Parameter(Mandatory = $false)]
    [string]
    $BuildNumber,
    [Parameter(Mandatory = $false)]
    [string]
    $PackageFile,
    [Parameter(Mandatory = $false)]
    [string]
    $CopyEntireFolder,
    [Parameter(Mandatory = $false)]
    [string]
    $TargetFolder,
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

#If Packagename provided
If($PackageName){
    #Convert YML File
    $root = Convert-YAMLFile -catalogFile $CatalogFile

    #Generate tag value to reference the correct build release
    if($Tag){
        $NewTag = $Tag
    } else{
        $NewTag = "main-$BuildNumber"
    }

    #If package name defined in catalog
    if($root.Catalog.Packages.$PackageName){
        #if Package Location Type set to GIT
        if($root.Catalog.Packages.$PackageName.LocationType -eq "GIT"){
            
            #if the environment is defined in the package
            if($root.Catalog.Packages.$PackageName.Environments.$Environment){
                #Update the repo, tag and artifactname values to reference the new release build
                $root.Catalog.Packages.$PackageName.Environments.$Environment.repo = "https://github.com/$Repository"
                $root.Catalog.Packages.$PackageName.Environments.$Environment.tag = $NewTag
                $root.Catalog.Packages.$PackageName.Environments.$Environment.artifactName = $BuildNumber
            } else{
                #Add the environment under the package with the repo, tag and artifactname values
                $root.Catalog.Packages.$PackageName.Environments.Add("$Environment",@{"repo"="https://github.com/$Repository";"tag"=$NewTag;"artifactName"=$BuildNumber})
            }
            
            #If next environment is specified
            if($NextEnvironment){
                #if the next environment is defined in the package
                if($root.Catalog.Packages.$PackageName.Environments.$NextEnvironment){
                    #Update the repo, tag and artifactname values to reference the new release build
                    $root.Catalog.Packages.$PackageName.Environments.$NextEnvironment.repo = "https://github.com/$Repository"
                    $root.Catalog.Packages.$PackageName.Environments.$NextEnvironment.tag = $NewTag
                    $root.Catalog.Packages.$PackageName.Environments.$NextEnvironment.artifactName = $BuildNumber
                } else {
                    #Add the next environment under the package with the repo, tag and artifactname values
                    $root.Catalog.Packages.$PackageName.Environments.Add("$NextEnvironment",@{"repo"=$root.Catalog.Packages.$PackageName.Environments.$Environment.repo;"tag"=$root.Catalog.Packages.$PackageName.Environments.$Environment.tag;"artifactName"=$root.Catalog.Packages.$PackageName.Environments.$Environment.artifactName})
                }
            }
        #if Package Location Type set to unc
        } elseif ($root.Catalog.Packages.$PackageName.LocationType -eq "UNC"){
            #if the environment is defined in the package
            if($root.Catalog.Packages.$PackageName.Environments.$Environment){
                #Remove UNC path and update the repo, tag and artifactname values to reference the new release build in GIT
                $root.Catalog.Packages.$PackageName.Environments.Remove("$Environment")
                $root.Catalog.Packages.$PackageName.Environments.Add("$Environment",@{"repo"="https://github.com/$Repository";"tag"=$NewTag;"artifactName"=$BuildNumber})
            } else{
                #Add the environment under the package with the repo, tag and artifactname values
                $root.Catalog.Packages.$PackageName.Environments.Add("$Environment",@{"repo"="https://github.com/$Repository";"tag"=$NewTag;"artifactName"=$BuildNumber})
            }
            
            #If next environment is specified
            if($NextEnvironment){
                #if the next environment is defined in the package
                if($root.Catalog.Packages.$PackageName.Environments.$NextEnvironment){
                    #Remove UNC path and update the repo, tag and artifactname values to reference the new release build in GIT
                    $root.Catalog.Packages.$PackageName.Environments.Remove("$NextEnvironment")
                    $root.Catalog.Packages.$PackageName.Environments.Add("$NextEnvironment",@{"repo"=$root.Catalog.Packages.$PackageName.Environments.$Environment.repo;"tag"=$root.Catalog.Packages.$PackageName.Environments.$Environment.tag;"artifactName"=$root.Catalog.Packages.$PackageName.Environments.$Environment.artifactName})
                } else {
                    #Add the next environment under the package with the repo, tag and artifactname values
                    $root.Catalog.Packages.$PackageName.Environments.Add("$NextEnvironment",@{"repo"=$root.Catalog.Packages.$PackageName.Environments.$Environment.repo;"tag"=$root.Catalog.Packages.$PackageName.Environments.$Environment.tag;"artifactName"=$root.Catalog.Packages.$PackageName.Environments.$Environment.artifactName})
                }
            }

            #Set location type to GIT
            $root.Catalog.Packages.$PackageName.LocationType = "GIT"
        }
    #If package name not defined in catalog add it in the catalog with all required values
    } else{
        #Sets CopyEntireFolder to true or false depending on value provided
        if($CopyEntireFolder -eq "false"){
            $CopyEntireFolderValue = $false
        } else{
            $CopyEntireFolderValue = $true
        }
        #If package sub folder specified add it to the catalog, otherwise don't add to the catalog
        if($PackageSubfolder){
            $root.Catalog.Packages.Add("$PackageName",@{"PackageName"=$PackageFile;"PackageSubfolder"=$PackageSubfolder;"Environments"=@{"$Environment"=@{"repo"="https://github.com/$Repository";"tag"=$NewTag;"artifactName"=$BuildNumber}};"LocationType"="GIT";"CopyEntireFolder"=$CopyEntireFolderValue;"TargetFolder"=$TargetFolder})
        } else{
            $root.Catalog.Packages.Add("$PackageName",@{"PackageName"=$PackageFile;"Environments"=@{"$Environment"=@{"repo"="https://github.com/$Repository";"tag"=$NewTag;"artifactName"=$BuildNumber}};"LocationType"="GIT";"CopyEntireFolder"=$CopyEntireFolderValue;"TargetFolder"=$TargetFolder})
        }
    }
#If package name not provided then loop through catalog and update next environment values to reference new release builds in the previous environment  
} else{
    $root = Convert-YAMLFile -catalogFile $CatalogFile
    $Packages = $root.Catalog.Packages

    foreach ($PackageName in $Packages.Keys){
        #If location type set to GIT update next environment tag and artifactname, if not exist add next environment under package with repo, tag and artifactname referencing new realease build
        if($Packages[$PackageName]["LocationType"] -eq "GIT"){
            if($Packages[$PackageName]["Environments"][$Environment]){
                if($Packages[$PackageName]["Environments"][$NextEnvironment]){
                    #If tag specified update the git values to reference the new release build
                    if($Packages[$PackageName]["Environments"][$NextEnvironment]["tag"]){
                        $Packages[$PackageName]["Environments"][$NextEnvironment]["tag"] = $Packages[$PackageName]["Environments"][$Environment]["tag"]
                        $Packages[$PackageName]["Environments"][$NextEnvironment]["artifactName"] = $Packages[$PackageName]["Environments"][$Environment]["artifactName"]
                    #If no tag specified it is a unc path so remove the value and replace it with the git values that reference the new build
                    } else{
                        $Packages[$PackageName]["Environments"].Remove("$NextEnvironment")
                        $Packages[$PackageName]["Environments"].Add("$NextEnvironment",@{"repo"=$Packages[$PackageName]["Environments"][$Environment]["repo"];"tag"=$Packages[$PackageName]["Environments"][$Environment]["tag"];"artifactName"=$Packages[$PackageName]["Environments"][$Environment]["artifactName"]})
                    }
                } else {
                    $Packages[$PackageName]["Environments"].Add("$NextEnvironment",@{"repo"=$Packages[$PackageName]["Environments"][$Environment]["repo"];"tag"=$Packages[$PackageName]["Environments"][$Environment]["tag"];"artifactName"=$Packages[$PackageName]["Environments"][$Environment]["artifactName"]})
                }
            }
        } elseif($Packages[$PackageName]["LocationType"] -eq "UNC"){
            if($Packages[$PackageName]["Environments"][$Environment]){
                if($Packages[$PackageName]["Environments"][$NextEnvironment]){
                    #Update Next Environment specified with the UNC value specified for the Previous Environment
                    $Packages[$PackageName]["Environments"][$NextEnvironment] = $Packages[$PackageName]["Environments"][$Environment]
                } else {
                    $Packages[$PackageName]["Environments"].Add("$NextEnvironment",$Packages[$PackageName]["Environments"][$Environment])
                }
            }
        }
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
    #caters for if catalog was updated during the process of this running so it can pull the latest and update from there
    $pushResult = git push PipelineOrigin main 2>&1
    while($pushResult -match "error: failed to push some refs"){
        git pull PipelineOrigin main
        $pushResult = git push PipelineOrigin main 2>&1
    }
    $SHA_NEW=$(git rev-parse HEAD)
    echo ("NEW_SHA=" + "$SHA_NEW") >> $env:GITHUB_ENV
} else{
    try{
        git remote add PipelineOrigin "https://$($AppName):$Token@github.com/ebetsystems/metro-pipeline.git"
        git add $CatalogFile
        git commit -m "Update catalog for $NextEnvironment"
        #caters for if catalog was updated during the process of this running so it can pull the latest and update from there
        $pushResult = git push PipelineOrigin "main" 2>&1
        while($pushResult -match "error: failed to push some refs"){
            git pull PipelineOrigin main
            $pushResult = git push PipelineOrigin "main" 2>&1
        }
    } catch{
        git add $CatalogFile
        git commit -m "Update catalog for $NextEnvironment"
        #caters for if catalog was updated during the process of this running so it can pull the latest and update from there
        $pushResult = git push 2>&1
        while($pushResult -match "error: failed to push some refs"){
            git pull PipelineOrigin main
            $pushResult = git push 2>&1
        }
    }
}