# App ↔ API Integration Plan

This covers how `lapo-app` (this repo) and `lapo-api` should work together to
power the mobile app, based on what's actually built in both repos today —
not a greenfield proposal.

## Current state

**`lapo-api`** is a public, read-only data API (`api.lakeafton.com`)
serving astronomy/observatory data. Routes are namespaced under `/v1`
(observatory routes directly under `/v1`, celestial routes under
`/v1/celestial`, e.g. `GET /v1/hours`, `GET /v1/celestial/whatsup-next`);
legacy unversioned paths (`/hours`, `/whatsup-next`, etc.) still work via
301 redirects to their `/v1` equivalents.

**`lapo-app`** already has a real (if small) SwiftUI iOS app wired up to
consume two of those endpoints:
- `LAPOClient.swift` fetches `hours()` and `whatsUpNext()`
- `AppStore.swift` calls both on `refresh()` and publishes them for the UI
- `HoursCard.swift` / `WhatsUpList.swift` render the results

Android has no code yet (`android/` is just a placeholder).

## The routing mismatch this section used to describe is resolved

This section previously flagged that `LAPOClient` requested `v1/hours` and
`v1/celestial/whatsup-next` while `lapo-api` served unversioned routes,
meaning every request would 404. `lapo-api` has since added the `/v1`
namespace described above (with legacy paths redirecting forward, not
removed), so both of `LAPOClient`'s requests now resolve to real,
namespaced routes exactly as written — no client-side path change needed.

The response *shapes* the app expects are still correct — `HoursResponse`
matches `/v1/hours`'s real nested `{ hours: { prettyHours, open, close } }`
payload exactly.

## Expanding what the app surfaces

The API already has more than enough to make this a genuinely useful "plan
your visit" app without any new backend work:

- `/v1/weather/current` + `/v1/weather/forecast` — "is tonight worth it" at a glance
- `/v1/schedule` — the observatory's public viewing schedule (distinct from
  `/v1/hours`, which is just open/close times)
- `/v1/celestial/visiblePlanets` / `/v1/celestial/moon` / `/v1/celestial/sun`
  — richer sky detail beyond `/v1/celestial/whatsup`'s summary list, for a
  "details" screen per object

Each of these is a `GET` with the same response pattern as the two already
integrated — adding them to `LAPOClient` and `AppStore` is mechanical.

## Android

There's nothing to integrate yet — `android/` has no project. Given the iOS
app's `AppStore`/`LAPOClient` split is a clean, minimal pattern (a single
async client + one `@Published`-backed store), a first Android pass could
mirror that shape directly (a repository class hitting the same JSON
endpoints, a ViewModel exposing the same two calls) rather than needing its
own design pass. Recommend deferring Android until the iOS app's endpoint
coverage above is fleshed out, so there's a single proven integration
pattern to port instead of building both in parallel.

## Volunteer features are a separate concern

The "Create volunteer login mechanism" task (email + confirmation code,
handbooks, scheduling) in this same Todoist section has **no home in either
repo as they stand** — `lapo-api` has no user/account model at all (every
route above is public, read-only data with no per-user identity), and
there's nothing in `lapo-app` for it to log into yet either.

Don't bolt volunteer auth onto `lapo-api` as-is — it would mix a public,
cacheable data API with private user data in the same service and deploy.
If volunteer features are wanted in this same mobile
app, the cleaner path is a **second, small backend** (even just a few
routes: request-code, verify-code, session) that `lapo-app` talks to
separately from `LAPOClient`, rather than expanding `lapo-api`'s scope.
That's a bigger decision than this plan should make unilaterally — flagging
it here so it's an explicit choice, not a default.
