# Two themes and independent accent

Approved: 17 October 2026. Replace seven presets with light/dark plus nine accents; neutral backgrounds, 1 px panel outlines, guest access, persistence and migration. Default: dark/light green. Preserve prior project work and the approved app icon.

- [x] Inspect current theme usage and project graph.
- [x] Add behaviour checks for colour contrast, persistence and migration.
- [x] Implement theme tokens and independent preferences.
- [x] Replace profile controls and restyle affected screens.
- [x] Review rendered profile, palette, auth, standings and match cards.
- [x] Verify narrow screens and large text.
- [x] Complete regression tests, static analysis and Android APK.
- [x] Refresh code graph and record final results.

Verification: 18 Flutter tests passed; visual snapshots for both themes reviewed. Analyzer: no errors or warnings, 67 informational notices. Android debug APK built. Code graph refreshed: 1178 nodes, 2177 edges. Source graph retains known limitations for a pre-existing C header and unsupported extensions.

Phone authorization renewed by the user. APK installed successfully with existing application data retained. The app starts, USB reverse to port 8000 is restored and backend responds. Verified on the phone: profile exposes separate theme/accent settings, the theme picker contains light/dark and the palette contains all nine requested colours. Current preference left unchanged; app left on profile.
