# Collecta — Mobile App (Flutter)

Phone-first treasury client for Collecta, adapted from the "Institutional
FinOps" web designs (sidebar → bottom nav, tables → stacked cards). Talks to the
Dart/Firebase backend via callables; ships **mock-first** so it runs offline
today.

## Run it

```bash
cd mobile
flutter pub get
flutter run            # or: flutter run -d chrome / -d windows
```

Sign in with anything (the mock backend logs you into the PCEA Kimuchu demo
org). Everything is seeded from the designs.

## What's inside

- **State**: Riverpod 3 (`state/`), providers refresh on `backendChangesProvider`.
- **Data**: `data/collecta_api.dart` (interface) with `MockCollectaApi` (seeded,
  default) and `FirebaseCollectaApi` (`httpsCallableFromUrl`). Switch via
  `useMock` in `data/api_provider.dart`.
- **Design system**: `theme/` — emerald `#006837` / mint `#00E599` / slate,
  Plus Jakarta Sans headings + Inter tabular figures.
- **Navigation**: `router.dart` (go_router) — auth gate + 5-tab bottom nav shell.

### Screens (`lib/features/`)
Login · Dashboard (metrics, trend + rails charts, recent, top collections) ·
Collections (cards, sharable link, STK trigger, create sheet) · Members
(directory, add sheet, filters) · **Ledger** · Settings.

### Ledger — the WhatsApp workflow
`features/ledger/` selects a collection, then filters contributors by
**All / Full / Partial / Pending** (see `utils/ledger.dart` `buildLedger`, which
derives paid-status from completed payments vs the per-member expected amount).
`buildWhatsAppPayload` renders the audit-formatted broadcast text; **Send to
WhatsApp** opens the app via the real WhatsApp glyph (`assets/icons/whatsapp.svg`
→ `WhatsAppIcon`) using `whatsapp://send` with a `wa.me` fallback. An M-Pesa
Verified Audit Stream lists each settlement.

## Icons / emojis
No emoji glyphs anywhere. Generic UI uses Material vector icons; WhatsApp and the
Collecta mark are dedicated SVG assets in `assets/icons/`.

## Going live (real backend)
1. `flutterfire configure` (adds `firebase_options.dart`); `Firebase.initializeApp`
   in `main.dart`.
2. Deploy the Dart functions; set `FirebaseCollectaApi.functionsBaseUrl` to your
   Cloud Run host.
3. Set `useMock = false` in `data/api_provider.dart`.

The `CollectaApi` interface and model `fromMap`s already match the deployed
callables (ISO-8601 timestamps, whole-KES amounts, initiated/pending/completed).

## Verify
`flutter analyze` → clean. `flutter test` → boots to the login gate.
