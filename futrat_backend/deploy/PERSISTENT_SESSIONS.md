# Persistent sign-in — 24 November 2026

## Deploy

Upload the updated Backend through Deploy Desk, including `app/`,
`requirements.txt`, and `deploy/`. Preserve the working server `.env`.
No new environment values, database server or public ports are required.
Use the existing backup procedure before deploying.

Run from `/srv/projects/futrat_backend`:

```bash
docker compose --env-file .env -f compose.prod.yml up -d --build --wait --wait-timeout 120 futrat-api
curl --fail https://176.108.255.248/health/ready
```

Do not use `--no-build` for this source/dependency update. The usual startup
metadata creation adds the new `auth_sessions` table to the existing Futrat
database; existing user, favorite, rating and prediction records are retained.
The change is additive, with no edits to other projects' databases.

The Android app can continue using the old API during rollout, but persistent
sign-in requires this backend update. After both sides are updated, sign in
once to obtain a device session. Expired old access tokens cannot be exchanged
for new sessions without signing in.

## Contract and lifetime

Login/registration retain `access_token` and `token_type` and add
`refresh_token` and `expires_in`. Old clients ignore the extra fields.
The access lifetime now actually uses `ACCESS_TOKEN_EXPIRE_MINUTES`.

`POST /auth/refresh` accepts a JSON `refresh_token` and returns an access token
without asking for the password. The opaque device key is generated from
48 random bytes and only its SHA-256 hash is stored server-side. It has no
inactivity or absolute timeout, as explicitly requested. The app stores the
key using the existing secure storage and never stores the password.

The device key remains stable when refreshing: simultaneous requests and a
lost refresh response can retry safely. The app coalesces concurrent refreshes,
retries a protected request at most once, and retains credentials on network
and server failures. Credential writes and account changes are ordered and
guarded against stale asynchronous completions.

`POST /auth/logout` accepts the same key and idempotently revokes that device's
session. Session-bound access tokens are rejected immediately after revocation;
other devices remain signed in. The app removes all local credentials even if
the logout server request fails. Offline local logout cannot acknowledge remote
revocation; an operator can revoke a lost device's row in `auth_sessions`.
Deleting app data removes the local key. Server-side revocation or loss of the
database session record requires sign-in again.

## Security review

Validation errors for refresh/logout use the credential error sanitizer and
never echo submitted keys. Tests cover invalid inputs, hashing, revocation,
cross-account session claims, old tokens, long inactivity, lost responses and
client races. No keys, passwords or `.env` values were read during development.

The dependency review found a reachable TLS trust issue in the old certifi
bundle. `certifi` is pinned to 2026.10.19 in both hashed lockfiles; other package
versions were retained. See [OSV](https://osv.dev/vulnerability/GHSA-6q48-6c7w-9gw2).

Remaining advisory matches were assessed against this application's reachable
paths; review again by 24 December 2026 or before changing JWT algorithms,
key sources, DNS parsing, ASN.1 handling or telemetry integrations:

- `python-jose` algorithm-confusion advisory: production explicitly permits
  HS256 only and uses a private secret; no public DER/PEM keys or caller-supplied
  algorithms enter verification. [OSV](https://osv.dev/vulnerability/GHSA-3qf3-8w2g-rqmx)
- `ecdsa` Minerva advisory: the application does not sign ECDSA or perform ECDH;
  sessions use HS256. The upstream advisory has no planned library fix.
  [OSV](https://osv.dev/vulnerability/GHSA-wj6h-64fc-37mp)
- `dnspython` WKS zone-file parsing: no attacker-controlled zone files are
  parsed by the application. [OSV](https://osv.dev/vulnerability/GHSA-vvf4-9x63-8xvv)
- `pyasn1` decoder advisories: the HTTP and HS256 JWT paths do not decode
  attacker-supplied ASN.1, certificates or RSA keys.
  [OSV](https://osv.dev/vulnerability/GHSA-2qm8-x737-gmw5)
- `opentelemetry-api` traceparent parsing: the backend does not extract trace
  context from untrusted JSON/MCP carriers.
  [OSV](https://osv.dev/vulnerability/GHSA-mf5v-w3w3-f6cg)
