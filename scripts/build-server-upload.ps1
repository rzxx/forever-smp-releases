param([string]$Pack = "")

$ErrorActionPreference = "Stop"
$sourceRoot = Split-Path -Parent $PSScriptRoot
$versionLine = Get-Content (Join-Path $sourceRoot "pack.toml") |
    Where-Object { $_ -match '^version = "([^"]+)"$' } | Select-Object -First 1
if ($versionLine -notmatch '^version = "([^"]+)"$') { throw "pack.toml has no pack version" }
$version = $Matches[1]
if ([string]::IsNullOrWhiteSpace($Pack)) {
    $Pack = Join-Path $sourceRoot "dist/Forever-SMP-$version.mrpack"
}
if (-not (Test-Path -LiteralPath $Pack -PathType Leaf)) { throw "Build the client MRPack first: $Pack" }

# Always stage from pinned downloads and committed templates, never a running
# server directory with its authentication database or test registration secret.
$staging = Join-Path $sourceRoot "dist/server-upload-$version-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $staging | Out-Null
& (Join-Path $PSScriptRoot "install-files.ps1") -Side server -GameDirectory $staging -Pack $Pack

$setup = Join-Path $staging "SETUP"
New-Item -ItemType Directory -Path $setup | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceRoot "server/config") -Destination $setup -Recurse
foreach ($name in @("server.properties.recommended", "world-setup.commands.txt", "launch-permissions.commands.txt")) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot "server/$name") -Destination $setup
}
Copy-Item -LiteralPath (Join-Path $sourceRoot "server/README.md") -Destination (Join-Path $staging "READ-ME-FIRST.md")
Copy-Item -LiteralPath (Join-Path $sourceRoot "server/README.md") -Destination (Join-Path $setup "server-reference.md")
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "add-offline-player.ps1") -Destination $setup

Add-Type -AssemblyName System.IO.Compression
$zipPath = Join-Path $sourceRoot "dist/Forever-SMP-$version-server-setup.zip"
$temporaryZip = "$zipPath.new"
[System.IO.Compression.ZipFile]::CreateFromDirectory($staging, $temporaryZip)
Move-Item -LiteralPath $temporaryZip -Destination $zipPath -Force
Write-Host "Server upload: $zipPath"
Write-Host "Upload mods; apply SETUP templates after the first start. Install the matching Fabric runtime through the host."
