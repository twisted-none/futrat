# Club badge repair

## Diagnosed production data

On 25 November 2026, `/api/matches` returned no `logo_url` for 9 of 16 RPL clubs
and all 102 Russian Cup clubs. The ESPN `rus.1/teams` catalog did contain club
logos, including Krasnodar (`11336`). Importers previously kept existing club
rows without filling missing logos. GOAL fixture badges can be null even when
the separate team catalog has artwork.

The two tournament badges themselves were already present in the device cache.
The image proxy also returned HTTP 403 during desktop probes, so the mobile
loader now prefers original images and uses the proxy as fallback.

## Deploy

Upload the Backend folder using Deploy Desk and its existing `.copyignore`.
Keep the existing server `.env`, database and networks. No database migration,
table recreation or manual SQL update is needed.

Use the existing single-line deployment command:

```sh
FUTRAT_PROXY_NETWORK=futrat_proxy FUTRAT_DATABASE_NETWORK=futrat_database docker compose --env-file .env -f compose.prod.yml up -d --build --wait --wait-timeout 120 futrat-api
```

The background full sync runs at startup and every six hours. It first fills
missing Russian club logos from one free ESPN catalog request, including teams
whose historic match-import checkpoints are complete. GOAL then supplies
remaining Russian Cup artwork from a paginated league team catalog, using the
existing key, shared seven-day cache and daily request budget. Failure of the
artwork catalog does not stop importing fixtures. Team/match IDs and user data
are preserved; existing nonempty valid logos are not overwritten.

APK 2.3.2+13 asks `/api/team-badges?ids=...` for only missing club artwork,
in batches of at most 100, with at least five minutes between checks while
active. It updates today's local fixture snapshot and prefetches the images.
This avoids clearing the entire daily cache after deploying the repair. Older
backends that lack the endpoint remain usable; only badge refresh is skipped.

## Verify

Check `/health/ready`, then `/api/team-badges?ids=<Krasnodar-local-team-id>` or
the club's entries in `/api/matches`. The badge should be a nonempty image URL.
An upstream catalog may still lack artwork for some lower-division clubs;
the application retains a placeholder rather than inventing a logo.

No server credential or production `.env` value is included in these steps.
