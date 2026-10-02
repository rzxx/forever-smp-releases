#requires -Version 7
param(
    [string]$InstallerRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'installer'),
    [string]$ReleaseTool = ''
)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
if ($ReleaseTool) { $ReleaseTool = (Resolve-Path -LiteralPath $ReleaseTool).Path }
$InstallerRoot = [IO.Path]::GetFullPath($InstallerRoot, (Get-Location).Path)
Push-Location $sourceRoot
try {
    & (Join-Path $PSScriptRoot 'build.ps1')
    if (-not $ReleaseTool) {
        $manifest = Join-Path $InstallerRoot 'Cargo.toml'
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
            throw 'Clone rzxx/forever-smp-installer beside this checkout as installer, pass -InstallerRoot, or pass -ReleaseTool. The installer repo owns the recipe tool.'
        }
        & cargo build --locked --release --manifest-path $manifest -p forever-release
        if ($LASTEXITCODE) { throw 'Recipe tool build failed.' }
        $metadata = & cargo metadata --locked --no-deps --format-version 1 --manifest-path $manifest
        if ($LASTEXITCODE) { throw 'Unable to read recipe tool metadata.' }
        $ReleaseTool = Join-Path ($metadata | ConvertFrom-Json).target_directory 'release/forever-release.exe'
    }
    $line = Get-Content pack.toml | Where-Object { $_ -match '^version = "([^"]+)"$' } | Select-Object -First 1
    if ($line -notmatch '^version = "([^"]+)"$') { throw 'Missing pack version.' }
    $version = $Matches[1]
    & $ReleaseTool build . "dist/Forever-SMP-$version.mrpack" "dist/releases/$version"
    if ($LASTEXITCODE) { throw 'Pack recipe export failed.' }
    Write-Host "Unsigned pack release candidate: dist/releases/$version"
} finally { Pop-Location }
