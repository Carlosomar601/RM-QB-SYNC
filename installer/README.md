# RMQBsync – Installer

`build_installer.ps1` (in the repository root) produces **one** file:
`installer\output\RMQBsync-Setup.exe`.

That installer is fully self-contained. It installs with **no Internet connection**: no
downloads, no winget/choco, no .NET, no WebView2, and no Flutter SDK on the client. The app
itself only needs Internet at runtime, to reach QuickBooks Online.

## One-time preparation (developer machine, with Internet)

1. **Flutter** (stable). Put it on the `PATH`, set `FLUTTER_ROOT`, or install it at `C:\src\flutter`.
2. **Visual Studio 2022 Build Tools** with the *Desktop development with C++* workload and
   the Windows 10/11 SDK (`flutter doctor` must show it in green).
3. **Inno Setup 6**. Its `ISCC.exe` is found on the `PATH`, through `ISCC_PATH`, or in Program Files.
4. **Prerequisites to bundle.** Place these in `installer\prereqs\` (see `prereqs\README.md`):

   | File | Source |
   |---|---|
   | `prereqs\vc_redist.x64.exe` | https://aka.ms/vs/17/release/vc_redist.x64.exe |
   | `prereqs\vcruntime\msvcp140.dll` | `C:\Windows\System32` (or `.\build_installer.ps1 -CollectRuntimeDlls`) |
   | `prereqs\vcruntime\vcruntime140.dll` | same |
   | `prereqs\vcruntime\vcruntime140_1.dll` | same |

5. *(Optional)* **Intuit credentials preloaded.** Copy `factory-secrets.example.json` to
   `factory-secrets.local.json` and fill it in.
   - This file is git-ignored.
   - The installer copies it to `%ProgramData%\RMQBsync\factory-secrets.json`.
   - On first launch the app imports it into Windows secure storage and **deletes the plaintext**.
   - If credentials are already stored, the file is ignored.

## Build

```powershell
.\build_installer.ps1                 # build + verify + package
.\build_installer.ps1 -SkipBuild      # package the existing build only
.\build_installer.ps1 -Version 1.2.0  # set the version explicitly
```

The script fails with a clear message if any of these is missing:

- `vc_redist.x64.exe` or one of the runtime DLLs;
- `rmqbsync.exe`, `flutter_windows.dll`, `data\app.so` or `data\icudtl.dat`;
- the assets, `sqlite3.dll` or the plugin DLLs.

## What the installer does

- **Program files.** Installs to `C:\Program Files\RMQBsync`, 64-bit, with administrator rights.
  - It uses the same `AppId` as the old C# version, so it updates that version in place.
  - It stops and removes the old `RMQBsync` Windows service, which frees port 5177.
  - It wipes the program folder before copying the new files.
- **Visual C++ runtime.** Installs the bundled runtime only if the registry key
  `HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64` does not have `Installed=1`.
  It runs it with `/install /quiet /norestart`. It also copies the runtime DLLs next to the exe
  as a fallback.
- **Data.** Creates `%ProgramData%\RMQBsync`, which holds the database and logs. Users have write
  access to it. It is kept on upgrade **and on uninstall**.
- **Shortcuts.** Adds a Start Menu shortcut, plus a desktop shortcut if you choose that option.
- **Start with Windows** (optional, checked by default). Adds an `HKLM\...\Run` entry that starts
  the app minimized to the system tray, so scheduled syncs run.
- **Uninstall.** Closes the app and removes the program files. The data stays.

## Upgrading from the previous version (C#/Blazor)

The old version used the same path, `%ProgramData%\RMQBsync\rmqbsync.db`, for an EF Core
database. On first launch the new app detects it and imports what it can.

- **Imported:** account mappings, the schedule and the **entire sync history**. The history keeps
  the duplicate rule working for dates already sent to QuickBooks.
- **Backup:** the old file is moved to `rmqbsync-legacy-<date>.db` in the same folder.
- **Not imported:** users and QuickBooks tokens. They are tied to the old encryption, so after the
  upgrade you have to:
  - log in with the new temporary `admin` password;
  - reconnect QuickBooks in Configuración;
  - enter the Intuit credentials again, unless they are bundled through `factory-secrets.local.json`.

## First launch on the client

- **Initial admin.** The app creates the user `admin` with a **temporary password**.
  - The login screen shows it.
  - It is also saved in `%ProgramData%\RMQBsync\primer-acceso.txt`.
  - The user must change it on the first login, and the file is then deleted automatically.
- **Setup assistant.** It walks you through four steps:
  1. The POS IP and port.
  2. Intuit credentials and QuickBooks connection.
  3. Account mapping.
  4. Scheduling.

> **Note on secrets.** Tokens and credentials are stored with Windows secure storage (DPAPI) for
> the **Windows user** who runs the app. Use the same Windows user that will leave the app
> running in the tray.

## Logs

`%ProgramData%\RMQBsync\logs\rmqbsync.log`. It rotates over 5 files of 2 MB each. Tokens and
secrets are redacted.
