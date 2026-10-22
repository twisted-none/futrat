param([string]$InterfaceAlias = 'Беспроводная сеть')

$ErrorActionPreference = 'Stop'
$network = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
$address = @($network.IPv4Address.IPAddress)[0]
if (-not $address -or -not $network.IPv4DefaultGateway) {
    throw 'Connect the laptop to Wi-Fi or the phone hotspot before building.'
}
$apiUrl = "http://${address}:8000"
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterExecutable = if ($flutterCommand) { $flutterCommand.Source } else { 'C:/flutter/bin/flutter.bat' }
Write-Output "Building Futrat for $apiUrl"
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & $flutterExecutable build apk --debug --no-pub "--dart-define=API_BASE_URL=$apiUrl"
    if ($LASTEXITCODE -ne 0) { throw 'Flutter APK build failed.' }
} finally {
    Pop-Location
}
