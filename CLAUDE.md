# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Listel** (`wish_nesita`) — Flutter mobile app for creating and sharing wishlists/product collections. Brazilian Portuguese UI. Targets Android (primary), iOS secondary.

## Common Commands

```bash
flutter pub get                          # Install dependencies
flutter run                              # Run in development
flutter analyze                          # Lint (flutter_lints)
flutter test                             # Run all tests
flutter test test/path/to_test.dart      # Run a single test file
flutter build apk                        # Build Android APK

# Code generation (Isar models)
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch       # Watch mode during development
```

> **Note**: Riverpod code generation (`@riverpod` annotations) is **disabled** due to an incompatibility between `isar_generator` (requires `analyzer <6.x`) and `riverpod_generator`. All providers are written manually. Do not re-enable until `isar_generator` supports `analyzer ^7.x`.

## Architecture

Clean Architecture with feature-based folder structure under `lib/`:

```
lib/
  core/           # Shared infrastructure
    config/       # Supabase credentials (app_config.dart)
    database/     # IsarService singleton
    router/       # GoRouter config + route constants
    theme/        # Material 3 theming
    services/     # Notifications, share intent
  features/
    auth/
    collections/
    items/
    sharing/
    settings/
    items_search/
    share_intent/
    onboarding/
    print_scanner/
    update/
```

Each feature follows the pattern:
- `data/` — Isar/Supabase models, repository implementations, data sources
- `domain/` — entities, repository interfaces, use cases
- `presentation/` — pages, widgets, Riverpod providers

## State Management (Riverpod)

All providers are **manual** (no `@riverpod` codegen). Key patterns used:

- `StreamProvider` — reactive Isar queries and Supabase Realtime streams
- `AsyncNotifierProvider` — mutations (create/update/delete) with async state
- `Provider` — synchronous deps (repositories, services)

Key providers: `authStateProvider`, `collectionsNotifierProvider`, `collectionsStreamProvider`, `sharedCollectionsStreamProvider`, `itemsStreamProvider`, `themeSettingsProvider`.

## Navigation

GoRouter with deep linking scheme `listel://invite?code=<code>`. Routes are defined as constants in `lib/core/router/app_routes.dart`. Nested routes exist under `/collection/:id` (edit, create item) and `/item/:id` (edit).

## Data Persistence

**Local**: Isar 3.x (`IsarService.getInstance()` / `IsarService.db`) — collections, items, theme settings. Model files have generated `.g.dart` counterparts (do not edit manually).

**Remote**: Supabase — shared collections and items only. The local Isar record stores `remoteId` and `inviteCode` to link with Supabase rows.

## External Services

- **Supabase**: Auth (email/password), PostgreSQL (shared data), Realtime subscriptions
- **Metadata extraction**: Open Graph parsing from product URLs (Amazon, Shopee, ML, Shein, etc.)
- **Price search**: Mercado Livre direct scraping + SerpAPI (orchestrated via `PriceSearchOrchestrator`)
- **OCR**: Google ML Kit (`google_mlkit_text_recognition`) for print scanning feature

## Available Skills

Use these commands with `/skill-name` to leverage specialized workflows:

### `/tlc-spec-driven`
Adaptive feature planning with 4 phases (Specify → Design → Tasks → Execute). Use for:
- Planning new features (requirements, design, task breakdown)
- Implementing with atomic commits and verification
- Mapping codebase structure and conventions
- Quick fixes and ad-hoc tasks

Example: `/tlc-spec-driven` when planning the next feature.

### `/simplify`
Review changed code for reuse, quality, and efficiency. Use after significant code changes to identify improvements.

### `/loop`
Run a prompt or command on a recurring interval. Use for:
- Monitoring builds: `loop 5m flutter analyze`
- Watching tests: `loop 10m flutter test`
- Polling deployment status

### `/schedule`
Create and manage scheduled remote agents (cron-based). Use for:
- Automated daily tasks
- Scheduled alerts or reports
- Recurring maintenance jobs

### `/update-config`
Configure Claude Code harness settings. Use for:
- Permissions management
- Environment variables
- Automated hooks and workflows

### `/keybindings-help`
Customize keyboard shortcuts. Use to rebind or add chord keybindings.
