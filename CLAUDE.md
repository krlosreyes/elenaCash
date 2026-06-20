# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on Chrome (web)
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=<your-web-client-id>

# Build web release
flutter build web --dart-define=GOOGLE_CLIENT_ID=<your-web-client-id>

# Regenerate Riverpod code-gen after changing any @riverpod annotated file
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development (auto-regenerates on save)
dart run build_runner watch --delete-conflicting-outputs

# Analyze
flutter analyze

# Run tests
flutter test
flutter test test/path/to/test_file.dart  # single file
```

## Architecture

Feature-first structure: `lib/features/<feature>/data|domain|presentation`.

```
lib/
  core/
    constants/   # AppColors, AppConstants (thresholds, defaults, Firestore collection names)
    router/      # GoRouter (app_router.dart + .g.dart) — auth guard + ShellRoute
    theme/       # AppTheme (dark + light, DM Sans via google_fonts)
    utils/       # CurrencyFormatter, DateHelpers, Validators
  features/
    auth/
    conscious_plan/
    dashboard/
    debts/
    education/
    fastlane_engine/
    habit_engine/
    monthly_review/
    onboarding/
    savings_goals/
    settings/
  shared/
    providers/   # firebase_providers.dart — FirebaseAuth, Firestore, Storage, currentUserId
```

## Key Patterns

**Riverpod v3 code-gen** — every provider uses `@riverpod` annotation. After editing any provider file, run `build_runner build`. Never edit `.g.dart` files manually.

**GoRouter auth guard** — the router is created once via `appRouterProvider`. Auth changes trigger `router.refresh()` via `ref.listen` on `authStateProvider` and `currentUserProvider`. Do not recreate the router on auth changes.

**ShellRoute = bottom nav** — all screens that need the `BottomNavigationBar` must be nested inside the `ShellRoute` in `app_router.dart`. Screens outside it (onboarding, habit modals, monthly review) render without the nav bar.

**Firestore collections** per user:
```
users/{uid}
  consciousPlan/current     ← ConsciousPlanEntity
  fastlaneEngine/current    ← FastLaneEntity + MoneyTreeBranches[]
  debts/{debtId}
  savingsGoals/{goalId}
  monthlySnapshots/{YYYY-MM}
  habitEngine/current
  educationProgress/current
```

**Race condition** — `authStateChanges` fires before Firestore doc is created after registration. `AuthRepositoryImpl.authStateChanges` builds a `UserModel` from Firebase Auth data as fallback when `doc.exists == false`.

**Google Sign-In web** — `GoogleSignIn` is lazy-initialized only when `signInWithGoogle()` is called. Pass `GOOGLE_CLIENT_ID` via `--dart-define` at build/run time.

## Financial Concepts

- **Conscious Spending Plan** (Ramit Sethi): 4 buckets — Fixed Costs (~55%), Savings (~7.5%), Investments (~7.5%), Guilt-Free (~30%)
- **FastLane / Árbol del Dinero** (MJ DeMarco): tracks passive income sources. Score 0–100 based on passive income ratio. Roadmap: `sinRumbo → viaLenta → viaRapida → elite`
- **Habit Engine** (Duhigg): Keystone habit = "Ritual Quincenal" (5-min check every payday). Craving Pause = 24h delay on impulse purchases.

## Firebase

- Project: `elenacash-b899b`
- Credentials: `lib/firebase_options.dart` (already configured)
- Crashlytics: disabled in debug mode (`kDebugMode` guard in `main.dart`)
- Firestore offline persistence: enabled in `firebase_providers.dart`
- RevenueCat API keys: set in `AppConstants.revenueCatApiKeyAndroid` / `revenueCatApiKeyIOS`

## Theme

`ThemeMode` is controlled by `themeModeProvider` (SharedPreferences-backed). `ElenaCashApp` in `main.dart` watches this provider. The settings screen toggles between dark/light/system.
