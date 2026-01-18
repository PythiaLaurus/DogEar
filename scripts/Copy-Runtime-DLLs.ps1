# scripts/Copy-Runtime-DLLs.ps1
# Copies MSVC runtime files to the build directory.

param (
    [string]$BuildDir
)

$RuntimeFiles = @(
    "msvcp140.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll"
)

# Check if the build directory exists
if (-not (Test-Path $BuildDir)) {
    Write-Host "Error: Build directory not found at $BuildDir" -ForegroundColor Red
    exit 1
}

Write-Host "Injecting MSVC Runtimes into: $BuildDir" -ForegroundColor Cyan

# Copy each file
foreach ($file in $RuntimeFiles) {
    $source = Join-Path $env:SystemRoot "System32\$file"
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $BuildDir -Force
        Write-Host "Successfully copied: $file" -ForegroundColor Green
    }
    else {
        Write-Host "Warning: Could not find $file in System32" -ForegroundColor Yellow
    }
}