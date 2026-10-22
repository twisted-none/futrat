# Match navigation and typography

Approved 18 October 2026: group today/live matches by league with favorites first; bundle IBM Plex Sans; equal thirds for three-tab league navigation; replace the round dropdown with a sheet/grid and previous/next controls; open team profiles from names/badges in standings and matches. Preserve theme/accent settings and separate favorite actions from navigation.

- [x] Inspect scoped graph and relevant UI sources.
- [x] Add behaviour tests for grouping, layout and navigation.
- [x] Bundle four IBM Plex Sans weights and original license.
- [x] Implement grouped feeds and shared team links.
- [x] Implement equal tabs and round picker.
- [x] Review real-font snapshots in both themes.
- [x] Complete regression checks, analyzer and APK.
- [ ] Install and verify on connected phone.
- [x] Update graph and final results.

Checks: 28 Flutter tests passed; analyzer has no errors/warnings and 67 existing informational notices. Confirmed all four font weights and the license in the final APK. Installed on phone with application data preserved; USB port 8000 reverse restored, backend responds. Phone was locked at the start of final UI checks; awaiting user unlock for device navigation checks.

Code graph refreshed: 1255 nodes, 2300 edges. Known pre-existing C-header extraction warning remains.
