param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_]{3,16}$')]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$ServerDirectory
)

$ErrorActionPreference = 'Stop'

# Minecraft's offline-mode UUID is the version-3 MD5 UUID of this exact string.
# A vanilla `whitelist add <name>` can resolve a paid account's online UUID instead.
$bytes = [Text.Encoding]::UTF8.GetBytes("OfflinePlayer:$Name")
$hash = [Security.Cryptography.MD5]::HashData($bytes)
$hash[6] = ($hash[6] -band 0x0f) -bor 0x30
$hash[8] = ($hash[8] -band 0x3f) -bor 0x80
$hex = -join ($hash | ForEach-Object { $_.ToString('x2') })
$uuid = '{0}-{1}-{2}-{3}-{4}' -f $hex.Substring(0, 8), $hex.Substring(8, 4), $hex.Substring(12, 4), $hex.Substring(16, 4), $hex.Substring(20, 12)

$path = Join-Path (Resolve-Path -LiteralPath $ServerDirectory) 'whitelist.json'
$players = @()
if (Test-Path -LiteralPath $path) {
    $players = @(Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}
$players = @($players | Where-Object { $_.name -ine $Name })
$players += [pscustomobject]@{ uuid = $uuid; name = $Name }

$temp = "$path.tmp"
ConvertTo-Json -InputObject $players -Depth 3 | Set-Content -LiteralPath $temp -Encoding utf8
Move-Item -LiteralPath $temp -Destination $path -Force
Write-Output "Whitelisted $Name with offline UUID $uuid. Run 'whitelist reload' in the server console."
