# scripts/Gen-Release-Note.ps1
# Generates release notes from Changelog.md and Release.template.md.

param (
    [string]$Version,
    [string]$DistDir,
    [string]$FileName,
    [string]$ReleaseNoteFileName
)

$TemplatePath = Join-Path $PSScriptRoot "Release-Note-Template.md"
$ChangelogPath = Join-Path $PSScriptRoot "Changelog.md"
$OutputPath = Join-Path $DistDir $ReleaseNoteFileName

# Check if files exist
if (!(Test-Path $TemplatePath)) {
    throw "Template file not found at $TemplatePath" 
}
if (!(Test-Path $ChangelogPath)) { 
    $ChangelogText = "No specific changes listed." 
}
else { 
    $ChangelogText = Get-Content $ChangelogPath -Raw  -Encoding UTF8 
}

# Calculate hash
$ExePath = Join-Path $DistDir $FileName
if (!(Test-Path $ExePath)) { 
    throw "Installer not found at $ExePath" 
}
$Hash = (Get-FileHash $ExePath -Algorithm SHA256).Hash

# Reads template file and replace placeholders
$Template = Get-Content $TemplatePath -Raw -Encoding UTF8
$Date = Get-Date -Format "yyyy-MM-dd"

$FinalNote = $Template `
    -replace '\{\{VERSION\}\}', $Version `
    -replace '\{\{CHANGELOG\}\}', $ChangelogText `
    -replace '\{\{FILENAME\}\}', $FileName `
    -replace '\{\{HASH\}\}', $Hash `
    -replace '\{\{DATE\}\}', $Date

# Write to file
$FinalNote | Out-File -FilePath $OutputPath -Encoding utf8 -Force
Write-Host "Success: Release notes generated at $OutputPath" -ForegroundColor Green
