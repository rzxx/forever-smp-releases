#requires -Version 7
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
Push-Location $sourceRoot
try {
    & (Join-Path $PSScriptRoot 'build.ps1')
    $line = Get-Content pack.toml | Where-Object { $_ -match '^version = "([^"]+)"$' } | Select-Object -First 1
    if ($line -notmatch '^version = "([^"]+)"$') { throw 'Missing pack version.' }
    $version = $Matches[1]
    $settings = Get-Content release.toml -Raw
    $presetList = [regex]::Match($settings, '(?s)public_presets\s*=\s*\[(.*?)\]')
    if (-not $presetList.Success) { throw 'Missing reviewed public presets.' }
    $allowed = @([regex]::Matches($presetList.Groups[1].Value, '"([^"]+)"') | ForEach-Object { "overrides/$($_.Groups[1].Value)" })
    $archive = [IO.Compression.ZipFile]::OpenRead((Join-Path $sourceRoot "dist/Forever-SMP-$version.mrpack"))
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            if ($entry.FullName -ne 'modrinth.index.json' -and $entry.FullName -notin $allowed) {
                throw "Unexpected file in client pack: $($entry.FullName)"
            }
        }
        foreach ($name in $allowed) {
            if (-not $archive.GetEntry($name)) { throw "Missing reviewed preset: $name" }
        }
        $reader = [IO.StreamReader]::new($archive.GetEntry('modrinth.index.json').Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        if ($manifest.versionId -ne $version) { throw 'Exported version differs from pack.toml.' }
        $dh = @($manifest.files | Where-Object { $_.path -match '^mods/DistantHorizons-.*\.jar$' })
        if ($dh.Count -ne 1 -or $dh[0].env.client -ne 'optional' -or $dh[0].env.server -ne 'required') {
            throw 'Incorrect exported Distant Horizons sides.'
        }
        Write-Host "Checked $($manifest.files.Count) mod entries, $($allowed.Count) reviewed presets, version and DH sides."
    } finally { $archive.Dispose() }
} finally { Pop-Location }
