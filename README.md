# RMQBsync (Flutter, Windows)

RMQBsync reads sales and payment totals from the **Retail Manager** POS over the LAN. It then posts
them to **QuickBooks Online** as a single balanced journal entry per date range. A sync can be
started by hand (Vista Previa / Sincronizaciones) or run on a schedule.

The interface is in Spanish and guided step by step. Contextual help is available with F1, and
there is a Help Center, a first-run setup assistant and an onboarding tour.

## Structure

```
lib/core/            pure domain: journal entry, scheduling, duplicates, POS address
lib/data/pos/        Retail Manager client (dio), aggregation, providers with live reconfiguration
lib/data/quickbooks/ OAuth (loopback 127.0.0.1:5177), tokens, API, retries, idempotency
lib/data/db/         drift (SQLite) in %ProgramData%\RMQBsync\rmqbsync.db
lib/services/        sync pipeline, scheduler, auth, logger, tray, start-up
lib/features/        screens (Inicio, Vista Previa, Mapeo, Configuración, …)
lib/ui/guided/       guided-UX kit (StepWizard, ScreenHeader, HelpTip, banners)
installer/           Inno Setup + prerequisites (offline installation)
```

## Development

```powershell
flutter pub get
dart run build_runner build      # regenerates app_database.g.dart
flutter analyze
flutter test
flutter run -d windows
```

You need the Flutter stable SDK and Visual Studio 2022 Build Tools with the C++ workload. The
C++ toolchain is also used by `flutter test`, because `package:sqlite3` compiles its native
library with build hooks.

## Installer

```powershell
.\build_installer.ps1
```

See [installer/README.md](installer/README.md) for the prerequisites to place in
`installer\prereqs\`.
