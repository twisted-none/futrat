# Backend over the phone hotspot

## Latest build — 20 October 2026

The registration-update APK build helper detected a different current Wi-Fi address, `192.168.1.56`, and builds with `API_BASE_URL=http://192.168.1.56:8000`. The `10.158.238.191` hotspot setup below records the previously verified connection, not the current address. This new build has not been installed or checked from the phone yet. Ensure the phone can reach the chosen network and check firewall/VPN rules for the current addresses before assuming that local API health proves phone connectivity.

Final check on 20 October: localhost API returned 200, but direct access to `192.168.1.56:8000` timed out from the laptop even without environment proxies. This current LAN setup is not working yet. Registration changes did not alter VPN/firewall rules.

## Address and build

`ApiClient` uses `AppConstants.baseUrl`, provided through `--dart-define=API_BASE_URL=...`.
The development fallback remains `http://127.0.0.1:8000` for USB/emulator workflows.
LAN builds must supply the Wi-Fi address, not the VPN adapter address.

For the current connection, the laptop is `10.158.238.191`, and the phone/hotspot is
`10.158.238.176`. Build from `futrat_mobile`:

```powershell
./tool/build-phone-lan.ps1
# Equivalent for the current address:
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.158.238.191:8000
```

The helper discovers the address of the selected Wi-Fi interface. If DHCP assigns a
different laptop address, rebuild and reinstall the APK. The laptop, Docker and the
phone hotspot must stay on. This does not publish the API to the internet.

## Windows setup

Run `futrat_backend/scripts/enable-phone-lan.ps1` as Administrator while connected
to the phone hotspot. It creates a temporary on-link route for the hotspot gateway,
and an inbound rule for TCP 8000 restricted to that phone, laptop address and Wi-Fi
interface. Other ports and firewall profiles remain enabled.

Amnezia can clone local routes onto its VPN adapter. For the phone and laptop's own
IPv4 host routes only, the helper lowers the priority of those VPN copies. The
route changes live in ActiveStore and may need reapplying after reconnection.
No VPN credentials or configuration files are read or modified.

The script's success result means settings were applied; actual connectivity must
still be checked from the phone. VPN filtering can block LAN even with a correct
route and Windows firewall rule. Use Amnezia's site/IP split settings to exclude
the two local addresses while preserving the existing list and selected mode.
Do not invert the split mode or disable KillSwitch as an automatic workaround.

References:
- [Amnezia split tunneling](https://docs.amnezia.org/documentation/instructions/vpn-split-tunneling/)
- [Reported Windows local-route capture issue](https://github.com/amnezia-vpn/amnezia-client/issues/2830)

## Verification without USB forwarding

ADB can control the device over USB while the app's HTTP traffic goes over Wi-Fi.
Keep `adb reverse --list` empty and check the explicit LAN address from the phone:

```powershell
adb -s f03f9967 shell "curl --noproxy '*' --connect-timeout 5 --max-time 8 -sS http://10.158.238.191:8000/"
```

After that succeeds, launch the installed app and verify match data. A successful
APK installation alone does not prove LAN connectivity.

## Verified on 18 October 2026

Installed the LAN debug APK on MT2111 without clearing app data. Amnezia remained connected after the user added the phone and laptop `/32` exclusions to the existing bypass list. Phone curl returned HTTP 200 for both health and the match list (7,688,879 bytes), with no ADB reverse mappings. The installed app displayed «Матчи сегодня», league groups and match cards. All 38 Flutter tests passed, including a test compiled with the LAN API_BASE_URL; analyzer had no errors/warnings and the existing 67 informational notices. Code graph refreshed.
