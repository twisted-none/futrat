# Registration validation and empty-account cleanup

Approved: nickname minimum 3, password minimum 6, two fields without email, unique nicknames, readable errors, removal of the verified empty account. Preserve existing accounts and guest access.

- [x] Reproduce missing validation and disappearing errors with regression tests.
- [x] Add server/client validation, two-field form and readable error states.
- [x] Add normalized unique nickname key and transactional legacy PostgreSQL migration.
- [x] Keep existing password hashes/email sessions and protect profile renames.
- [x] Docker/PostgreSQL suite: 121 tests passed; migration and cleanup covered.
- [x] Deploy backend and verify live validation, wrong-login errors and health 200.
- [x] Delete verified account ID 2 and seven favorites, confirm other account unchanged.
- [x] Flutter: full 54 tests pass; 14 affected/visual checks pass after shortening the button text; analyzer has no errors/warnings (61 existing info), visual review passes in both themes.
- [x] APK built successfully for the currently detected Wi-Fi API address `http://192.168.1.56:8000`.
- [x] Refresh code graph: 1514 nodes, 2803 edges, 92 communities. Existing unsupported C-header warning remains; semantic documentation indexing was not run.

Details: futrat_backend/docs/registration.md. No phone installation in this step; USB verification was postponed by the user earlier.

Remaining external issue: localhost health is 200, but the current LAN address `192.168.1.56:8000` times out from the laptop. The APK is built but its configured network path is not operational; network restoration and phone installation are pending. Registration/validation/cleanup were verified independently on the working local API.
