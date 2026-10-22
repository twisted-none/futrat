# Nickname registration

Approved and implemented on 20 October 2026: the Flutter registration/login screen has nickname and password fields, with no email field. The minimum registration lengths are 3 Unicode code points after trimming the nickname, and 6 Unicode code points for the password. Passwords are passed unchanged: leading/trailing spaces are significant. All-space passwords, NUL and new passwords exceeding bcrypt's 72 UTF-8 byte boundary are rejected instead of silently truncated. Nickname control/format characters are rejected.

## API and errors

`POST /auth/register` accepts `{ "username": "Player", "password": "example-password" }`. `POST /auth/login` uses the same two fields. Both return the existing token shape. Optional email on registration and the old email login key remain supported for older clients; the new app does not send email. `/auth/me` returns nullable email for accounts created without one.

Validation returns HTTP 422 with a readable Russian `detail` plus field/message entries in `errors`. Submitted passwords or raw Pydantic inputs are not echoed. A taken nickname is 409, wrong credentials are 401 with the same “Неверный никнейм или пароль” message for missing users and bad passwords. Database unique violations are mapped to the relevant nickname/email conflict; unrelated integrity errors are not disguised as a taken nickname.

The Flutter form validates before sending requests, clears stale errors on editing or switching modes, and retains server errors after loading ends. Connection failures, timeouts, server failures, duplicate names and validation failures have readable messages. Partial registration success with a failed profile request explicitly says the account was created and asks the user to log in. Concurrent client submissions are ignored while the first request is active. Guest access remains available.

## Identity and compatibility

Nickname identity is `NFKC(trim(username)).casefold()`, stored as users.username_key with a database unique index and non-null constraint in PostgreSQL. ORM inserts/updates maintain the key; registration and profile rename share the same validation and uniqueness rules. Consequently `Player`, `player`, and full-width `Ｐｌａｙｅｒ` cannot create different accounts.

New JWTs use a string user ID as `sub` and `subject_type=user_id`. Nickname/profile changes do not invalidate them. Existing email-subject JWTs and email login remain supported. Login does not impose the new minimum password length on existing accounts, so older short passwords are still usable. Password hashing and legacy hash verification are unchanged.

`app/user_migration.py` runs after metadata creation, before initial users/workers/HTTP serving. It takes a PostgreSQL transaction advisory lock, checks existing nickname collisions, adds/backfills username_key, makes email optional, creates the unique index and enforces non-null normalized keys. All PostgreSQL changes are transactional and idempotent. Existing account IDs, names, emails, hashes and references are retained. A collision aborts with IDs; accounts are never automatically renamed or merged. Existing non-PostgreSQL schemas with mandatory email require a separate migration; fresh SQLite test schemas are supported. Do not roll back to the old email-required app after creating email-less accounts without planning compatibility.

## Requested cleanup

Before changing the database, exactly one blank-name account was found (ID 2); verification against the stored hash confirmed its password was empty. It had three team, three tournament and one player favorite, with no ratings/predictions. After tests passed, `app/user_cleanup.py` rechecked the explicit ID under a row lock, verified the empty password again, and deleted that account and its seven favorite links in one transaction. The other account was checked unchanged; no blank-name accounts remained. This cleanup is explicit, not a startup task or public endpoint. No hashes/passwords were printed or written into a report.

## Verification

Docker/Python 3.15/PostgreSQL: 121 tests passed, including legacy-schema upgrade, case/Unicode uniqueness, database collision handling, rename validation, old sessions/short passwords, sanitized errors and targeted account cleanup. The working API rejects empty/short registration and returns readable login errors. Flutter tests cover local validation, requests without email, exact passwords, persistent readable errors, network/structured errors, profile failure after registration, double submission and profiles without email. Visual previews use IBM Plex Sans at 320 logical pixels and text scale 1.25 in both themes, stored under `.tools/auth-previews/`.

The complete Flutter suite passed 54 tests; the final shorter “Создать аккаунт” label was then verified by 14 affected/visual tests. Analyzer: no errors/warnings, 61 pre-existing informational notices. The code graph was refreshed (1514 nodes, 2803 edges, 92 communities); documentation semantic indexing was not run.

The APK build helper detected the laptop's current Wi-Fi address as `192.168.1.56`, replacing the earlier `10.158.238.191` address for this new build. Installation and phone-to-server connectivity verification are still pending; phones must be on a network able to reach that address, and existing firewall/VPN exceptions may need adjusting. The address is a build-time setting, not server discovery.

Final network check: localhost returned HTTP 200, but direct access to `192.168.1.56:8000` timed out even from the laptop, including a check bypassing environment proxies. LAN connectivity is therefore a known unresolved issue, not a verified working path for this APK. No VPN/firewall changes were made by the registration task; USB/phone diagnostics had been deferred by the user.
