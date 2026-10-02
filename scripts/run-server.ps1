#requires -Version 7
param(
    [Parameter(Mandatory = $true)][string]$ServerDirectory,
    [string]$Java = 'java',
    [string]$MaximumMemory = '2G'
)
$ErrorActionPreference = 'Stop'
$ServerDirectory = (Resolve-Path -LiteralPath $ServerDirectory).Path
if (-not (Test-Path -LiteralPath (Join-Path $ServerDirectory 'fabric-server-launch.jar'))) {
    throw 'Install a Fabric server runtime in the test directory first.'
}
$javaCommand = (Get-Command $Java -ErrorAction Stop).Source
Push-Location $ServerDirectory
try {
    & $javaCommand "-Xmx$MaximumMemory" -XX:+UnlockDiagnosticVMOptions -XX:-G1UseTimeBasedHeapSizing -jar fabric-server-launch.jar nogui
    if ($LASTEXITCODE) { throw "Test server exited with code $LASTEXITCODE." }
} finally { Pop-Location }
