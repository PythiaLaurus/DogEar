# This file is used to update icons in the project.

# Source paths
$VisualResourcesDir = Join-Path $PSScriptRoot  "../visuals"

# App icon
$appIconName = "app_icon.ico"
$SourceAppIcon = Join-Path $VisualResourcesDir $appIconName

# Tray icon
$trayIconName = "tray_icon.ico"
$SourceTrayIcon = Join-Path $VisualResourcesDir $trayIconName

# Use app icon as tray icon
# Should delete this line using a different icon
Copy-Item -Path $SourceAppIcon -Destination $SourceTrayIcon -Force

# Target paths
$ProjectDir = Join-Path $PSScriptRoot  "../apps/dogear"
$AssetsDir = Join-Path $ProjectDir "assets/system"
$WindowsResourceDir = Join-Path $ProjectDir "windows/runner/resources"

$TargetAssetsAppIcon = Join-Path $AssetsDir $appIconName
$TargetAssetsTrayIcon = Join-Path $AssetsDir $trayIconName
$TargetWindowsAppIcon = Join-Path $WindowsResourceDir $appIconName

# Check if the source file exists
if (!(Test-Path $SourceAppIcon)) {
    Write-Error "Error: can't find $appIconName at $VisualResourcesDir"
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
Copy-Item -Path $SourceAppIcon -Destination $TargetAssetsTrayIcon -Force

# Windoes resources
Write-Host "Updating Windows Native Icon..." -ForegroundColor Cyan
Copy-Item -Path $SourceAppIcon -Destination $TargetWindowsAppIcon -Force

Write-Host "Successfully Updating All Icons" -ForegroundColor Green