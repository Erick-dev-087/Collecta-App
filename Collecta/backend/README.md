# Collecta — Backend (Dart Cloud Functions)

Payment reconciliation backend for Collecta: organizations create events/causes,
collect M-Pesa (Daraja STK Push) contributions, share hosted payment links, and
reconcile transactions.

Written in **Dart** on **Firebase Cloud Functions** (experimental Dart support)
with **Cloud Firestore** as the database.

## Stack & why it looks the way it does

- **Firebase Functions for Dart** (`firebase_functions` 0.8.x). Announced 2026;
  requires Dart SDK ≥3.9, Firebase CLI ≥15.15, and the Blaze plan to deploy.
  Enable once with: `firebase experiments:enable dartfunctions`.
- **Only HTTPS triggers deploy to production** (`onCall`, `onCallWithData`,
  `onRequest`). Firestore/Auth/Storage triggers are emulator-only, so there are
  **no background triggers** here — all logic runs through callables and two raw
  HTTP endpoints. Payment aggregates are folded in inline when the Daraja
  callback is processed, not via a Firestore trigger.
- **`firebase_admin_sdk`** provides Firestore + Auth handles (`app.firestore()`,
  `app.auth()`), built once in `bin/server.dart` and threaded through services.

### Deliberate design choices (portability against the young package APIs)

- Timestamps are stored as **ISO-8601 UTC strings** (`nowIso()`), not `Timestamp`
  objects — JSON-safe for callable responses and lexically sortable for the
  composite indexes.
- Document IDs are **self-generated** (`newId()`), avoiding reliance on auto-id.
- Aggregate updates use **read-modify-write transactions** rather than
  `FieldValue.increment` / `serverTimestamp`.
- `WriteBatch.update` keys are **`FieldPath`s** (unlike `Transaction.update` /
  `DocumentReference.update`, which take plain string keys) — see
  `OrgService.setDefaultDestination`.
- Functions that touch Daraja pass `secrets:` as an **inline list literal**
  (`[darajaConsumerSecret, darajaPasskey]`). The deploy build step extracts
  secrets by statically reading that literal, so a reference like `darajaSecrets`
  would silently fail to bind. This trips the `non_const_argument_for_const_parameter`
  lint (secrets can't be `const`); it's suppressed with an inline `// ignore:` —
  this matches the package's own README example.

## Layout

```
functions/
  bin/server.dart            # entry point: runFunctions → build ctx + services → register all
  lib/
    config/    context.dart  # AppContext (Firestore/Auth + collection accessors), nowIso/newId
               params.dart   # defineString/defineSecret params (Daraja + public URLs)
    constants/ enums.dart
    utils/     errors, validation, phone, csv, auth_context
    services/  auth, org, member, event, payment, payment_link, daraja
    handlers/  *_handlers.dart (onCall callables) + http_handlers.dart (onRequest)
```

## Functions

Callables (invoke from Flutter via `httpsCallableFromUrl` — name-based lookup is
not supported for Dart functions):

- Auth: `bootstrapOrganization`, `addStaff`, `getProfile`
- Org: `getOrganization`, `updateOrganization`, `listPaymentDestinations`,
  `addPaymentDestination`, `setDefaultPaymentDestination`, `removePaymentDestination`
- Members: `createMember`, `getMember`, `listMembers`, `updateMember`,
  `deleteMember`, `topContributors`, `inactiveMembers`, `importMembers`
- Events: `createEvent`, `getEvent`, `listEvents`, `updateEvent`, `eventAnalytics`
- Payments: `initiatePayment`, `getPaymentStatus`, `paymentHistory`,
  `listStuckPayments`, `reconcilePayment`, `exportPayments`
- Links: `createPaymentLink`, `listPaymentLinks`, `setPaymentLinkActive`

Raw HTTP (`onRequest`):

- `darajaCallback` — Safaricom STK callback webhook. Always acks `200 {ResultCode:0}`.
- `checkout` — public hosted checkout page. `GET ?c=<shortCode>` renders the
  payment form; `POST` initiates the STK push against the link.

## Configuration

Copy `.env.example` → `.env` (local) or `.env.<project>` (deploy) and set the
non-secret params. Secrets go to Cloud Secret Manager:

```
firebase functions:secrets:set DARAJA_CONSUMER_SECRET
firebase functions:secrets:set DARAJA_PASSKEY
```

Params: `DARAJA_ENV` (sandbox|production), `DARAJA_CONSUMER_KEY`,
`DARAJA_SHORTCODE`, `DARAJA_MOCK` (simulate STK without live calls),
`PUBLIC_CALLBACK_BASE_URL` (HTTPS URL Safaricom can reach), `PUBLIC_CHECKOUT_BASE_URL`.
Secrets: `DARAJA_CONSUMER_SECRET`, `DARAJA_PASSKEY`.

> Daraja runs against **sandbox** only. Passkeys are never returned to clients;
> `listPaymentDestinations` strips them. Financial collections are
> backend-write-only in `firestore.rules`.

## Develop / verify

```
cd functions
dart pub get
dart analyze                       # static checks
dart compile kernel bin/server.dart -o build/server.dill   # full type-check

firebase emulators:start           # from backend/ ; needs the dartfunctions experiment
```

Because Safaricom must reach `darajaCallback` over the public internet, expose the
functions emulator with a tunnel (e.g. ngrok) and set `PUBLIC_CALLBACK_BASE_URL`
to that HTTPS URL — this is the "sandbox creds + live webhooks" setup. Set
`DARAJA_MOCK=true` to exercise the full flow without a tunnel.
