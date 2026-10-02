param(
    [string]$Packwiz = "packwiz"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Path $dist -Force | Out-Null
if (-not (Get-Command $Packwiz -ErrorAction SilentlyContinue)) {
    $goInstall = Join-Path $env:USERPROFILE "go/bin/packwiz.exe"
    if (Test-Path -LiteralPath $goInstall) { $Packwiz = $goInstall }
    else { throw "packwiz was not found. Install it or pass -Packwiz <path>." }
}

Push-Location $root
try {
    & $Packwiz refresh
    if ($LASTEXITCODE -ne 0) { throw "packwiz refresh failed" }
    $versionLine = Get-Content (Join-Path $root "pack.toml") | Where-Object { $_ -match '^version = "([^"]+)"$' } | Select-Object -First 1
    if ($versionLine -notmatch '^version = "([^"]+)"$') { throw "pack.toml has no pack version" }
    $version = $Matches[1]
    $archivePath = Join-Path $dist "Forever-SMP-$version.mrpack"
    & $Packwiz modrinth export --output $archivePath
    if ($LASTEXITCODE -ne 0) { throw "packwiz modrinth export failed" }

    # Packwiz has one optional flag for both sides. The MRPack format can express
    # DH as optional on clients and required on the dedicated server.
    Add-Type -AssemblyName System.IO.Compression
    $archive = [System.IO.Compression.ZipFile]::Open($archivePath, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $indexEntry = $archive.GetEntry("modrinth.index.json")
        if ($null -eq $indexEntry) { throw "The exported MRPack has no modrinth.index.json" }
        $reader = [System.IO.StreamReader]::new($indexEntry.Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json }
        finally { $reader.Dispose() }

        $dhFiles = @($manifest.files | Where-Object { $_.path -match '^mods/DistantHorizons-.*\.jar$' })
        if ($dhFiles.Count -ne 1 -or $dhFiles[0].env.client -ne "optional" -or
            $dhFiles[0].env.server -ne "optional") {
            throw "Expected one optional-client/optional-server Distant Horizons entry in the export"
        }
        $dhFiles[0].env.server = "required"

        $indexEntry.Delete()
        $indexEntry = $archive.CreateEntry("modrinth.index.json", [System.IO.Compression.CompressionLevel]::Optimal)
        $writer = [System.IO.StreamWriter]::new($indexEntry.Open(), [System.Text.UTF8Encoding]::new($false))
        try { $writer.Write(($manifest | ConvertTo-Json -Depth 32)) }
        finally { $writer.Dispose() }
    }
    finally { $archive.Dispose() }
}
finally {
    Pop-Location
}
