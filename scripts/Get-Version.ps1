# scripts/Get-Version.ps1
# Reads the version from pubspec.yaml

$yaml = Get-Content "apps/dogear/pubspec.yaml" -Raw
# Use regular expression to match version: 1.0.0+1
if ($yaml -match 'version:\s*([^\s+]+)') {
    $version = $Matches[1]
    Write-Output $version
}
else {
    exit 1
}