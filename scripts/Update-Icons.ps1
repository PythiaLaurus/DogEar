# scripts/Update-Icons.ps1
# Updates icons in the project.

# Source paths
$VisualResourcesDir = Join-Path $PSScriptRoot  "../visuals"

# App icon
$appIconName = "app_icon.ico"
$SourceAppIcon = Join-Path $VisualResourcesDir $appIconName

# Tray icon
$trayIconName = "tray_icon.ico"
$SourceTrayIcon = Join-Path $VisualResourcesDir $trayIconName

# Target paths
$ProjectDir = Join-Path $PSScriptRoot  "../apps/dogear"
$AssetsDir = Join-Path $ProjectDir "assets/system"
$WindowsResourceDir = Join-Path $ProjectDir "windows/runner/resources"

$TargetAssetsAppIcon = Join-Path $AssetsDir $appIconName
$TargetAssetsTrayIcon = Join-Path $AssetsDir $trayIconName
$TargetWindowsAppIcon = Join-Path $WindowsResourceDir $appIconName

# Check if the source file exists
if (!(Test-Path $SourceAppIcon)) {
    Write-Error "Error: $appIconName not found at at $VisualResourcesDir"
    exit
}
if (!(Test-Path $SourceTrayIcon)) {
    Write-Error "Error: $trayIconName not found at at $VisualResourcesDir"
    exit
}

# Create the target directory if it doesn't exist
if (!(Test-Path $AssetsDir)) {
    New-Item -ItemType Directory -Force -Path $AssetsDir | Out-Null
}

# Replace existing files
# Flutter assets
Write-Host "Updating Flutter Assets Icon..." -ForegroundColor Cyan
Copy-Item -Path $SourceAppIcon -Destination $TargetAssetsAppIcon -Force
Copy-Item -Path $SourceTrayIcon -Destination $TargetAssetsTrayIcon -Force

# Windoes resources
Write-Host "Updating Windows Native Icon..." -ForegroundColor Cyan
Copy-Item -Path $SourceAppIcon -Destination $TargetWindowsAppIcon -Force

Write-Host "Successfully Updating All Icons" -ForegroundColor Green