# installer\prereqs

Place these files here **once**, on the developer machine (the only step that needs Internet).
They are git-ignored and get embedded in `RMQBsync-Setup.exe`, so the client install works offline.

```
installer\prereqs\
├─ vc_redist.x64.exe          Microsoft Visual C++ 2015-2022 Redistributable (x64)
│                             https://aka.ms/vs/17/release/vc_redist.x64.exe
└─ vcruntime\
   ├─ msvcp140.dll            app-local fallback copies of the runtime
   ├─ vcruntime140.dll
   └─ vcruntime140_1.dll
```

The three DLLs can be copied from `C:\Windows\System32` on any up-to-date x64 machine:

```powershell
.\build_installer.ps1 -CollectRuntimeDlls
```
