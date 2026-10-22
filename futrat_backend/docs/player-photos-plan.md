# Player photos outside sports APIs

Status: source research and implementation plan approved on 20 October 2026. Photo import is a separate future step; the current change only improves team/tournament logo contrast. No photo source or existing player mapping has been changed.

## Selected approach

Build a small, curated photo catalog from Wikimedia Commons. The app will display ordinary static image files from our storage. Wikidata can help locate the corresponding Commons file through P18; this is a metadata lookup, so discovery still uses a Wikimedia service, even though image delivery does not depend on ESPN/GOAL/TheSportsDB APIs.

Primary references checked on 20 October 2026:

- [Wikidata P18](https://www.wikidata.org/wiki/Property:P18): links an entity to a Commons media file.
- [Wikidata P569](https://www.wikidata.org/wiki/Property:P569): date of birth for identity verification.
- [Commons reuse instructions](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia): check the individual file license and provide the required attribution.
- [Commons technical guidance](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia/technical): access and reuse of files and thumbnails.

The existing database already has canonical player IDs, provider mappings, birth_date and photo_url/photo_source. Use the canonical ID as the catalog key so club and national-team appearances share the same portrait. An import must not rewrite player identities or create aliases on a name match alone.

## Ordered implementation

1. Audit a sample of players across the supported Russian/European clubs and national teams. Record which players have an identifiable, usable portrait, its age and framing. Do not promise complete coverage before this check.
2. Resolve a Wikidata identity using the full name and matching birth date; check football occupation and supporting team/country information. Ambiguous or incomplete identity matches go to manual review. An exact trusted external-ID mapping may also be reviewed and recorded.
3. Store a manifest containing canonical player_id, Wikidata entity, Commons file page, original file URL, author, license identifier/URL, required credit text, photo date when known, verification date and optional crop coordinates. Check the license for each file; the metadata license does not grant image rights.
4. Import verified files in a bounded background/offline process. Validate HTTPS source, redirects, MIME type, dimensions and byte limits. Use approved image hosts, decode/re-encode raster files, keep source/provenance and generate small portrait thumbnails. Keep an explicit persistent Docker media volume and backups rather than storing files in a temporary container layer.
5. Add a photo record linked to the canonical player and a stable media URL. Give manually verified local portraits priority over provider updates; current lineups.bind_player otherwise overwrites photo_url whenever a provider supplies a photo. Roll out using additive storage and explicit precedence rather than silently changing the old column's meaning.
6. Expose attribution to the app through a compact photo credit object and a visible “Фото и авторство” entry. Retain links to the source/license and indicate cropping where required. Review individual license requirements before publishing.
7. Display the same verified portrait in lineups, favorites, player profiles and match history. A missing or unverified photo keeps the existing neutral silhouette. Opening a screen must not trigger an external search.
8. Test namesakes, transliterations, transfers, club/national duplication, missing DOB, dead image links, provider overwrites, cropped portraits and missing credits. Measure sample coverage and storage/network cost before expanding the catalog.

## Alternatives considered

- [Sortitoutsi Cut-Out Faces](https://sortitoutsi.net/graphics/style/1/cut-out-player-faces) supplies a large collection of cut-out portraits designed for Football Manager. Its player identifiers require a separate mapping to our players. Availability for downloading is not evidence of permission to redistribute within Futrat; obtain suitable permission before adoption.
- [DF11 terms](https://www.df11faces.com/terms) explicitly require written permission to share artwork. It is not included in the proposed automatic import.

## Limits

Commons photos are not guaranteed to be current, uniformly cropped or present for every player. Prefer a verified portrait with known provenance to an automatic first search result. A uniform transparent cut-out collection is not promised by this plan. No bulk download, new crawler, database migration or photo endpoint is part of the current approved implementation.
