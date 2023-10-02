Param(
    [Parameter(Mandatory = $false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory = $false)]
    [string] $Branch
)

$ErrorActionPreference = "Stop"
$SERVER_DIR = "./Server"

if (Test-Path -Path $SERVER_DIR) {
    if ($Overwrite -or (Read-Host "$SERVER_DIR exists, delete? [y/n]") -eq 'y') {
        Write-Output "$SERVER_DIR exists, removing"
        Remove-Item -Recurse -Force $SERVER_DIR
    }
    else {
        Exit 1
    }
}

Write-Output "clone repo"
if ( $Branch.Length -gt 0 ) {
    Write-Output "Cloning branch $Branch"
    git clone -b $Branch https://dev.sp-tarkov.com/SPT-AKI/Server.git $SERVER_DIR
} 
else {
    Write-Output "Branch not given, using default branch"
    git clone https://dev.sp-tarkov.com/SPT-AKI/Server.git $SERVER_DIR
}

Set-Location $SERVER_DIR

$Head = git rev-parse --short HEAD
$Branch = git rev-parse --abbrev-ref HEAD

Write-Output "Current HEAD is at $Head in $Branch"

Write-Output "lfs"
git lfs fetch
git lfs pull

Write-Output "build"
Set-Location ./project
npm install
npm run build:debug

if ($IsLinux -eq $true) {
    $Os = "linux"
}
else {
    $Os = "win"
}
Write-Output $Os

Get-ChildItem ./build
$AkiMeta = (Get-Content ./build/Aki_Data/Server/configs/core.json |  ConvertFrom-Json -AsHashtable)
Write-Output $akiMeta
$ZipName = "Aki-Server-{0}-debug-{1}-{2}-Tarkov{3}.zip" -f $Os, $akimeta.akiVersion, $Head, $akimeta.compatibleTarkovVersion

Compress-Archive -Path ./build/* -DestinationPath "../$ZipName"
Write-Output "Built file: $ZipName"
Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
