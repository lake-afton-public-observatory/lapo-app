# App ↔ API Integration Plan

This covers how `lapo-app` (this repo) and `lapo-api` should work together to
power the mobile app, based on what's actually built in both repos today —
not a greenfield proposal.

## Current state

**`lapo-api`** is a public, unauthenticated read-only data API
(`api.lakeafton.com`) serving astronomy/observatory data: `/hours`,
`/planets`, `/visiblePlanets`, `/sun`, `/moon`, `/schedule`, `/whatsup`,
`/whatsup-next`, `/weather`, `/forecast`, `/mars-weather`, `/iss`,
`/iss-passes`, `/neo`. No routes are versioned or namespaced — everything
hangs directly off the root (e.g. `GET /hours`, not `GET /v1/hours`).

**`lapo-app`** already has a real (if small) SwiftUI iOS app wired up to
consume two of those endpoints:
- `LAPOClient.swift` fetches `hours()` and `whatsUpNext()`
- `AppStore.swift` calls both on `refresh()` and publishes them for the UI
- `HoursCard.swift` / `WhatsUpList.swift` render the results

Android has no code yet (`android/` is just a placeholder).

## The actual integration bug

`LAPOClient` requests `v1/hours` and `v1/celestial/whatsup-next`. Neither
path exists on the real API — the deployed routes are `/hours` and a
regex match on `whatsup[_-]next` at the root, with no `v1` or `celestial`
prefix anywhere in `lapo-api`. As written, **every request this app makes
today would 404** and immediately surface `LAPOError.badResponse`.

The response *shapes* the app expects are otherwise correct — `HoursResponse`
matches `/hours`'s real nested `{ hours: { prettyHours, open, close } }`
payload exactly. This is a pure routing mismatch, not a data-modeling one.

**Fix:** update `LAPOClient`'s two paths to `hours` and `whatsup-next`
(matching `lapo-api`'s actual, currently-unversioned routes) rather than
adding versioning to the live public API — `api.lakeafton.com` is already
deployed and may have other consumers; changing its URL structure to match
an app that hasn't shipped yet is the riskier direction.

## Expanding what the app surfaces

Once the two wired-up endpoints actually resolve, the API already has more
than enough to make this a genuinely useful "plan your visit" app without
any new backend work:

- `/weather` + `/forecast` — "is tonight worth it" at a glance
- `/schedule` — the observatory's public viewing schedule (distinct from
  `/hours`, which is just open/close times)
- `/visiblePlanets` / `/moon` / `/sun` — richer sky detail beyond `/whatsup`'s
  summary list, for a "details" screen per object

Each of these is a `GET`, unauthenticated, same response pattern as the two
already integrated — adding them to `LAPOClient` and `AppStore` is
mechanical once the path fix above lands.

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
route above is public, unauthenticated, read-only), and there's nothing in
`lapo-app` for it to log into yet either.

Don't bolt volunteer auth onto `lapo-api` as-is — it would mix a public,
cacheable, unauthenticated data API with private user data in the same
service and deploy. If volunteer features are wanted in this same mobile
app, the cleaner path is a **second, small backend** (even just a few
routes: request-code, verify-code, session) that `lapo-app` talks to
separately from `LAPOClient`, rather than expanding `lapo-api`'s scope.
That's a bigger decision than this plan should make unilaterally — flagging
it here so it's an explicit choice, not a default.
