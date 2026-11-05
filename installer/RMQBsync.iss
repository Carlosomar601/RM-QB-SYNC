; RMQBsync - instalador autocontenido (no requiere Internet para instalar).
; Se compila con build_installer.ps1, que verifica que todo exista antes.
;
;   ISCC.exe /DAppVersion=1.2.3 installer\RMQBsync.iss

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define AppName      "RM Ledger Sync"
; Technical name: install folder, data folder, Run key, service and setup file.
#define TechName     "RMQBsync"
#define AppExe       "rmqbsync.exe"
#define Publisher    "Retail Manager PR"
#define ReleaseDir   "..\build\windows\x64\runner\Release"
#define PrereqDir    "prereqs"

[Setup]
; Same AppId as the legacy C# installer, so this upgrades it in place.
AppId={{A8120646-D898-4A0F-BF26-BF0E1F6E77C1}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#Publisher}
AppComments=Sincroniza las ventas del POS Retail Manager con QuickBooks Online
DefaultDirName={autopf}\{#TechName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes
OutputDir=output
OutputBaseFilename=RMQBsync-Setup
SetupIconFile=..\assets\icons\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
; Tell Explorer to refresh icons at the end, so shortcuts never keep a cached old icon.
ChangesAssociations=yes
UninstallDisplayName={#AppName}
WizardStyle=modern
CloseApplications=force
RestartApplications=no
SetupLogging=yes
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#Publisher}
VersionInfoDescription=Instalador de {#AppName}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "startup"; Description: "Iniciar {#AppName} con Windows (minimizado en la bandeja) – recomendado para las sincronizaciones programadas"; GroupDescription: "Opciones:"
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Opciones:"; Flags: unchecked

[Dirs]
; Data folder survives upgrades and uninstall; users may write (DB, logs).
Name: "{commonappdata}\RMQBsync"; Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\RMQBsync\logs"; Permissions: users-modify; Flags: uninsneveruninstall

[InstallDelete]
; Clean program folder on upgrade (removes the legacy .NET/Blazor files).
; Data lives in %ProgramData%\RMQBsync and is never touched.
Type: filesandordirs; Name: "{app}\*"
; Shortcuts from versions named "RMQBsync" (now "RM Ledger Sync").
Type: filesandordirs; Name: "{commonprograms}\{#TechName}"
Type: files; Name: "{commondesktop}\{#TechName}.lnk"
Type: files; Name: "{userdesktop}\{#TechName}.lnk"

[Files]
; Complete Flutter release output: exe, flutter_windows.dll, plugin DLLs, data\ (app.so, icudtl.dat, assets).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Shortcut icon as its own file: a new path Windows has never cached (the desktop
; kept showing an old icon cached for rmqbsync.exe).
Source: "..\assets\icons\app_icon.ico"; DestDir: "{app}"; DestName: "rmledgersync.ico"; Flags: ignoreversion
; App-local VC++ runtime (fallback if the redistributable cannot be installed).
Source: "{#PrereqDir}\vcruntime\msvcp140.dll";     DestDir: "{app}"; Flags: ignoreversion
Source: "{#PrereqDir}\vcruntime\vcruntime140.dll";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#PrereqDir}\vcruntime\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
; Bundled VC++ 2015-2022 x64 redistributable, extracted only when needed (see [Code]).
Source: "{#PrereqDir}\vc_redist.x64.exe"; Flags: dontcopy
; Optional Intuit credentials seed (git-ignored). Imported to secure storage and deleted on first run.
#ifexist "factory-secrets.local.json"
Source: "factory-secrets.local.json"; DestDir: "{commonappdata}\RMQBsync"; DestName: "factory-secrets.json"; Flags: ignoreversion onlyifdoesntexist uninsneveruninstall; Permissions: users-modify
#endif

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\rmledgersync.ico"; Comment: "Abrir {#AppName}"
Name: "{group}\Carpeta de datos y registros"; Filename: "{commonappdata}\RMQBsync"
Name: "{group}\Desinstalar {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\rmledgersync.ico"; Comment: "Abrir {#AppName}"; Tasks: desktopicon

[Registry]
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "RMQBsync"; ValueData: """{app}\{#AppExe}"" --minimized"; Flags: uninsdeletevalue; Tasks: startup

[Run]
; Rebuild Windows' icon cache so the new icon shows immediately.
Filename: "{sys}\ie4uinit.exe"; Parameters: "-show"; Flags: runhidden waituntilterminated; StatusMsg: "Actualizando iconos..."
Filename: "{app}\{#AppExe}"; Description: "Abrir {#AppName} ahora"; Flags: nowait postinstall skipifsilent runasoriginaluser

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM {#AppExe}"; Flags: runhidden; RunOnceId: "KillApp"

[UninstallDelete]
; Leave %ProgramData%\RMQBsync (database, logs) intact by design.
Type: filesandordirs; Name: "{app}"

[Code]
function VCRedistInstalled(): Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed)
            and (Installed = 1);
end;

procedure RunHidden(const FileName, Params: String);
var
  Code: Integer;
begin
  Exec(FileName, Params, '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Code: Integer;
begin
  Result := '';
  { Legacy Blazor version ran as a Windows service on port 5177 - remove it. }
  RunHidden(ExpandConstant('{sys}\sc.exe'), 'stop RMQBsync');
  RunHidden(ExpandConstant('{sys}\sc.exe'), 'delete RMQBsync');
  { Close a running instance so files can be replaced. }
  RunHidden(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#AppExe}');

  { Install the bundled VC++ runtime only if missing (no Internet needed). }
  if not VCRedistInstalled() then
  begin
    WizardForm.PreparingLabel.Caption := 'Instalando Microsoft Visual C++ 2015-2022 (x64)...';
    ExtractTemporaryFile('vc_redist.x64.exe');
    if not Exec(ExpandConstant('{tmp}\vc_redist.x64.exe'), '/install /quiet /norestart', '',
                SW_HIDE, ewWaitUntilTerminated, Code) then
      Log('No se pudo ejecutar vc_redist.x64.exe; se usarán las DLL locales.')
    else if (Code = 3010) or (Code = 1641) then
      NeedsRestart := True
    else if (Code <> 0) and (Code <> 1638) then
      Log(Format('vc_redist.x64.exe terminó con código %d; se usarán las DLL locales.', [Code]));
    DeleteFile(ExpandConstant('{tmp}\vc_redist.x64.exe'));
  end;
end;
