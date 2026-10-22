param(
    [string]$InterfaceAlias = 'Беспроводная сеть',
    [string]$PhoneAddress,
    [string]$ResultPath
)

$ErrorActionPreference = 'Stop'
$result = @{ success = $false }
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run this script as Administrator to configure the local route and firewall.'
    }
    $network = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    $localAddress = @($network.IPv4Address.IPAddress)[0]
    $gateway = @($network.IPv4DefaultGateway.NextHop)[0]
    if (-not $localAddress -or -not $gateway) { throw 'Connected IPv4 network is required.' }
    if (-not $PhoneAddress) { $PhoneAddress = $gateway }
    if ($PhoneAddress -ne $gateway) {
        throw 'This setup expects the laptop to be connected to the phone hotspot.'
    }
    $route = Get-NetRoute -DestinationPrefix "$PhoneAddress/32" -InterfaceIndex $network.InterfaceIndex -ErrorAction SilentlyContinue
    if (-not $route) {
        New-NetRoute -DestinationPrefix "$PhoneAddress/32" -InterfaceIndex $network.InterfaceIndex -NextHop '0.0.0.0' -RouteMetric 1 -PolicyStore ActiveStore | Out-Null
    }
    # Amnezia mirrors newly added routes into its adapter with a lower metric.
    # Prefer Wi-Fi only for the phone and this laptop's own LAN address.
    foreach ($address in @($PhoneAddress, $localAddress)) {
        Get-NetRoute -DestinationPrefix "$address/32" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.InterfaceAlias -eq 'AmneziaVPN' } |
            Set-NetRoute -RouteMetric 4096 -ErrorAction Stop | Out-Null
    }
    $ruleName = 'Futrat-API-Phone-LAN'
    if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
        Set-NetFirewallRule -Name $ruleName -Enabled True -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -LocalAddress $localAddress -RemoteAddress $PhoneAddress -InterfaceAlias $InterfaceAlias -Profile Any | Out-Null
    } else {
        New-NetFirewallRule -Name $ruleName -DisplayName 'Futrat API - phone local network' -Enabled True -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -LocalAddress $localAddress -RemoteAddress $PhoneAddress -InterfaceAlias $InterfaceAlias -Profile Any | Out-Null
    }
    $result = @{ success = $true; localAddress = $localAddress; phoneAddress = $PhoneAddress; apiUrl = "http://${localAddress}:8000" }
    $result | ConvertTo-Json
} catch {
    $result.error = $_.Exception.Message
    Write-Output $result.error
} finally {
    if ($ResultPath) { $result | ConvertTo-Json | Set-Content -LiteralPath $ResultPath -Encoding UTF8 }
}
if (-not $result.success) { exit 1 }
