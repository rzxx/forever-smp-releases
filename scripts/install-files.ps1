param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("client", "server")]
    [string]$Side,

    [Parameter(Mandatory = $true)]
    [string]$GameDirectory,

    [string]$Pack = "",

    [switch]$IncludeOptional,

    [string[]]$OptionalMod = @(),

    [switch]$ApplyPackConfigs,
    [ValidateSet('en','ru')][string]$Language = 'en'
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http
function Save-DownloadLiteral([string]$Url, [string]$Path) {
    # Windows PowerShell 5.1's Invoke-WebRequest -OutFile resolves wildcards.
    # CameraOverhaul uses square brackets in its real filename. Stream through
    # .NET so both the filename and game folder are always treated literally.
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds(120)
    $response = $null
    $output = $null
    try {
        $response = $client.GetAsync($Url).GetAwaiter().GetResult()
        $null = $response.EnsureSuccessStatusCode()
        $output = [System.IO.File]::Create($Path)
        $response.Content.CopyToAsync($output).GetAwaiter().GetResult()
    }
    finally {
        if ($null -ne $output) { $output.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        $client.Dispose()
    }
}
function ClientMessage([string]$Key, [object[]]$Values) {
    $messages = @{
        Verified = @('Verified {0}', 'Проверено: {0}')
        Installed = @('Installed {0}', 'Установлено: {0}')
        Kept = @('Kept existing {0}', 'Сохранены ваши настройки: {0}')
        Backup = @('Backed up {0} to {1}', 'Резервная копия {0}: {1}')
        Complete = @('Installed {0} {1} mod files. Configure Minecraft and Fabric in your launcher separately.', 'Установлено модов: {0} ({1}). Minecraft и Fabric настраиваются отдельно в лаунчере.')
    }
    $index = 0
    if ($Language -eq 'ru') { $index = 1 }
    Write-Host ($messages[$Key][$index] -f $Values)
}

if ([string]::IsNullOrWhiteSpace($Pack)) {
    $sourceRoot = Split-Path -Parent $PSScriptRoot
    $versionLine = Get-Content (Join-Path $sourceRoot "pack.toml") |
        Where-Object { $_ -match '^version = "([^"]+)"$' } | Select-Object -First 1
    if ($versionLine -notmatch '^version = "([^"]+)"$') { throw "pack.toml has no pack version" }
    $Pack = Join-Path $sourceRoot "dist/Forever-SMP-$($Matches[1]).mrpack"
}

$root = [System.IO.Path]::GetFullPath($GameDirectory)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "GameDirectory must already exist: $root"
}
$rootPrefix = $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

$zip = [System.IO.Compression.ZipFile]::OpenRead([System.IO.Path]::GetFullPath($Pack))
try {
    $entry = $zip.GetEntry("modrinth.index.json")
    if ($null -eq $entry) { throw "The .mrpack has no modrinth.index.json" }
    $reader = [System.IO.StreamReader]::new($entry.Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json }
    finally { $reader.Dispose() }
}
finally { $zip.Dispose() }

if ($manifest.dependencies.minecraft -ne "26.3" -or $manifest.dependencies.'fabric-loader' -ne "0.19.5") {
    throw "This installer expects Minecraft 26.3 and Fabric Loader 0.19.5"
}

$optionalFiles = @($manifest.files | Where-Object { $_.env.$Side -eq "optional" })
if ($IncludeOptional -and $OptionalMod.Count -gt 0) {
    throw "Use either -IncludeOptional or -OptionalMod, not both."
}
$chosenOptional = @()
foreach ($prefix in $OptionalMod) {
    if ([string]::IsNullOrWhiteSpace($prefix) -or $prefix -notmatch '^[A-Za-z0-9_-]+$') {
        throw "OptionalMod entries must be filename prefixes using only letters, numbers, hyphens, or underscores."
    }
    $matches = @($optionalFiles | Where-Object {
        [System.IO.Path]::GetFileName($_.path).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($matches.Count -ne 1) {
        throw "OptionalMod '$prefix' matched $($matches.Count) files; use a unique filename prefix from the pack manifest."
    }
    if ($chosenOptional.path -contains $matches[0].path) {
        throw "OptionalMod '$prefix' was selected more than once."
    }
    $chosenOptional += $matches[0]
}
if ($Side -eq "client" -and @($chosenOptional | Where-Object {
    [System.IO.Path]::GetFileName($_.path).StartsWith("betterstats-", [System.StringComparison]::OrdinalIgnoreCase)
}).Count -gt 0) {
    # MRPack optional entries cannot express that Better Statistics Screen
    # requires the matching optional TCDCommons API build.
    $library = @($optionalFiles | Where-Object {
        [System.IO.Path]::GetFileName($_.path).StartsWith("tcdcommons-", [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($library.Count -ne 1) { throw "Expected one optional TCDCommons API dependency for Better Statistics Screen." }
    if ($chosenOptional.path -notcontains $library[0].path) { $chosenOptional += $library[0] }
}
$selected = @($manifest.files | Where-Object {
    $_.env.$Side -eq "required" -or
        ($IncludeOptional -and $_.env.$Side -eq "optional") -or
        ($chosenOptional.path -contains $_.path)
})
$expectedNames = @($selected | ForEach-Object { [System.IO.Path]::GetFileName($_.path) })
$modsDirectory = Join-Path $root "mods"
if (Test-Path -LiteralPath $modsDirectory) {
    $unexpected = @(Get-ChildItem -LiteralPath $modsDirectory -File -Filter "*.jar" |
        Where-Object { $expectedNames -notcontains $_.Name })
    if ($unexpected.Count -gt 0) {
        throw "The mods folder has other JARs. Use a clean game directory: $($unexpected[0].FullName)"
    }
}

foreach ($file in $selected) {
    $relative = [string]$file.path
    if (-not $relative.StartsWith("mods/", [System.StringComparison]::Ordinal) -or
        $relative.Contains("..") -or $relative.Contains("\") -or $relative.Contains(":")) {
        throw "Unexpected path in pack: $relative"
    }
    $destination = [System.IO.Path]::GetFullPath((Join-Path $root ($relative.Replace("/", "\"))))
    if (-not $destination.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Pack path escapes the game directory: $relative"
    }
    $expectedHash = ([string]$file.hashes.sha512).ToLowerInvariant()
    if (Test-Path -LiteralPath $destination) {
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA512).Hash.ToLowerInvariant() -ne $expectedHash) {
            throw "Existing file has different content: $destination"
        }
        ClientMessage 'Verified' @($relative)
        continue
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    $temporary = "$destination.download"
    try {
        $downloaded = $false
        $lastDownloadError = ''
        foreach ($url in $file.downloads) {
            if (([uri]$url).Scheme -ne "https") { continue }
            try {
                Save-DownloadLiteral -Url $url -Path $temporary
                $downloaded = $true
                break
            }
            catch {
                $lastDownloadError = $_.Exception.Message
                Remove-Item -LiteralPath $temporary -ErrorAction SilentlyContinue
            }
        }
        if (-not $downloaded) { throw "Could not download $relative. $lastDownloadError" }
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA512).Hash.ToLowerInvariant() -ne $expectedHash) {
            throw "Downloaded file failed SHA-512 verification: $relative"
        }
        Move-Item -LiteralPath $temporary -Destination $destination
        ClientMessage 'Installed' @($relative)
    }
    finally {
        Remove-Item -LiteralPath $temporary -ErrorAction SilentlyContinue
    }
}

if ($Side -eq "client") {
    # The pack ships client preferences as Modrinth overrides. Keep existing
    # player settings when this installer is rerun to update mod JARs.
    $configBackup = Join-Path $root ("forever-smp-backups/config-" + [guid]::NewGuid().ToString('N'))
    $zip = [System.IO.Compression.ZipFile]::OpenRead([System.IO.Path]::GetFullPath($Pack))
    try {
        $prefix = "overrides/config/"
        foreach ($entry in $zip.Entries) {
            if (-not $entry.FullName.StartsWith($prefix, [System.StringComparison]::Ordinal) -or
                $entry.FullName.EndsWith("/", [System.StringComparison]::Ordinal)) { continue }
            $relative = $entry.FullName.Substring("overrides/".Length)
            if ($relative.Contains("..") -or $relative.Contains("\") -or $relative.Contains(":")) {
                throw "Unexpected override path in pack: $relative"
            }
            $destination = [System.IO.Path]::GetFullPath((Join-Path $root ($relative.Replace("/", "\"))))
            if (-not $destination.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Pack override path escapes the game directory: $relative"
            }
            if (Test-Path -LiteralPath $destination) {
                if (-not $ApplyPackConfigs) {
                    ClientMessage 'Kept' @($relative)
                    continue
                }
                $backupPath = Join-Path $configBackup ($relative.Replace("/", "\"))
                New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
                Copy-Item -LiteralPath $destination -Destination $backupPath
                ClientMessage 'Backup' @($relative, $backupPath)
            }
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            $inputStream = $entry.Open()
            try {
                $outputStream = [System.IO.File]::Create($destination)
                try { $inputStream.CopyTo($outputStream) }
                finally { $outputStream.Dispose() }
            }
            finally { $inputStream.Dispose() }
            ClientMessage 'Installed' @($relative)
        }
    }
    finally { $zip.Dispose() }
}

$receipt = [ordered]@{
    packVersion = $manifest.versionId
    minecraft = $manifest.dependencies.minecraft
    fabricLoader = $manifest.dependencies.'fabric-loader'
    side = $Side
    installedAtUtc = [DateTime]::UtcNow.ToString('o')
    optionalMods = @($selected | Where-Object { $_.env.$Side -eq 'optional' } | ForEach-Object { $_.path })
    mods = @($selected | ForEach-Object { [ordered]@{path=$_.path; sha512=$_.hashes.sha512} })
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'forever-smp-install.json') -Encoding UTF8
ClientMessage 'Complete' @($selected.Count, $Side)
