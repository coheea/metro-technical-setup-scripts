#Create new directory to house all metro-external compressed packages
New-Item -Path ".\packages" -ItemType Directory

#Loop through all subfolders in metro-external and compress them a part from the .git and scripts folder. Saves them in the folder above
$FolderNames = Get-ChildItem -Path ".\" -Directory -Force -ErrorAction SilentlyContinue
foreach($FolderName in $FolderNames){
    if($FolderName.Name -match ".git" -or $FolderName.Name -match "scripts"){
    } else{
        Compress-Archive -Path $FolderName.FullName -DestinationPath ".\packages\$($FolderName.Name).zip"
    }
}

#loop through all the newly compressed packages and upload them into the main github release on the metro-external repo
$Packages = Get-ChildItem -Path ".\packages" -Force -ErrorAction SilentlyContinue
foreach($Package in $Packages){
    gh release upload $env:TAG_NAME $Package.FullName --clobber --repo "https://github.com/ebetsystems/metro-external"
}
