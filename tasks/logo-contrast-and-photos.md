# Logo contrast and player photo research

Approved scope, 20 October 2026: add selective light logo tiles in dark mode across team/tournament displays; retain light-mode behavior; research and document a photo source outside sports APIs without mass import.

- [x] Shared FootballLogo component with alpha-weighted pixel contrast and a bounded analysis cache.
- [x] Light tile only for predominantly low-contrast artwork in dark mode; contain fit, inner padding, subtle rounded corners; unchanged slot sizes.
- [x] Connect Today/Live, league rounds and recent games, tables, league navigation, favorites and match headers.
- [x] Handle theme/image changes and missing/invalid artwork.
- [x] Document Wikimedia catalog plan, identity verification, per-file credits, persistent storage and provider-overwrite protection.
- [x] Complete tests, analyzer, visual review and Android build: 47 Flutter tests pass, 16 affected logo/navigation tests rechecked after removing artwork clipping, both-theme visual review passes; no analyzer errors/warnings (61 existing info).
- [x] Refresh the code graph: 1450 nodes, 2685 edges, 88 communities. Existing unsupported C-header warning remains; documentation semantic indexing was not run.

Implementation: futrat_mobile/lib/widgets/football_logo.dart. Research: futrat_backend/docs/player-photos-plan.md.

Android debug APK built successfully with API_BASE_URL=http://10.158.238.191:8000, matching the current Wi-Fi address. This task did not install the APK on a phone. No new dependencies or backend/schema changes. Review fixed the navigation test's old placeholder-specific finder and removed image corner clipping; affected behavior rechecked successfully.
