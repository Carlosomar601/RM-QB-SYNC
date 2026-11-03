<#
.SYNOPSIS
  Builds RMQBsync (Flutter, Windows release) and packages ONE self-contained
  Inno Setup installer: installer\output\RMQBsync-Setup.exe

.DESCRIPTION
  1. Locates Flutter (PATH, FLUTTER_ROOT, C:\src\flutter).
  2. flutter build windows --release
  3. Verifies every required runtime file and installer prerequisite exists
     (fails loudly, e.g. when installer\prereqs\vc_redist.x64.exe is missing).
  4. Locates ISCC.exe (ISCC_PATH, PATH, Program Files) and compiles the installer.

  The resulting installer needs NO Internet connection to install.

.PARAMETER Version
  Installer version. Defaults to the version in pubspec.yaml.

.PARAMETER SkipBuild
  Reuse the existing build\windows\x64\runner\Release output.

.PARAMETER CollectRuntimeDlls
  Copy msvcp140.dll / vcruntime140.dll / vcruntime140_1.dll from this
  machine's System32 into installer\prereqs\vcruntime (offline convenience).
#>
[CmdletBinding()]
param(
  [string]$Version,
  [switch]$SkipBuild,
  [switch]$CollectRuntimeDlls
)

$ErrorActionPreference = 'Stop'
$root      = $PSScriptRoot
$release   = Join-Path $root 'build\windows\x64\runner\Release'
$installer = Join-Path $root 'installer'
$prereqs   = Join-Path $installer 'prereqs'
$vcrtDir   = Join-Path $prereqs 'vcruntime'

function Fail([string]$msg) {
  Write-Host ''
  Write-Host "ERROR: $msg" -ForegroundColor Red
  exit 1
}

function Find-Flutter {
  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  if ($env:FLUTTER_ROOT -and (Test-Path (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'))) {
    return (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat')
  }
  foreach ($p in @('C:\src\flutter\bin\flutter.bat', (Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat'))) {
    if (Test-Path $p) { return $p }
  }
  Fail 'No se encontró Flutter. Agréguelo al PATH o defina FLUTTER_ROOT.'
}

function Find-Iscc {
  if ($env:ISCC_PATH -and (Test-Path $env:ISCC_PATH)) { return $env:ISCC_PATH }
  # Real install locations first: package-manager shims on PATH can be broken
  # (e.g. a user profile path containing an apostrophe).
  $candidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
  )
  foreach ($p in $candidates) { if ($p -and (Test-Path $p)) { return $p } }
  $cmd = Get-Command iscc -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  Fail 'No se encontró ISCC.exe (Inno Setup 6). Instálelo o defina ISCC_PATH.'
}

# --- Version --------------------------------------------------------------
if (-not $Version) {
  $line = Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)' | Select-Object -First 1
  $Version = if ($line) { $line.Matches[0].Groups[1].Value } else { '1.0.0' }
}
Write-Host "RMQBsync $Version" -ForegroundColor Cyan

# --- Optional: collect runtime DLLs from this machine ------------------------
if ($CollectRuntimeDlls) {
  New-Item -ItemType Directory -Force $vcrtDir | Out-Null
  foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    $src = Join-Path $env:WINDIR "System32\$dll"
    if (-not (Test-Path $src)) { Fail "No existe $src en este equipo." }
    Copy-Item $src $vcrtDir -Force
  }
  Write-Host "DLL del runtime copiadas a $vcrtDir"
}

# --- Prerequisites (checked BEFORE the long build) ---------------------------
$missing = @()
if (-not (Test-Path (Join-Path $prereqs 'vc_redist.x64.exe'))) {
  $missing += 'installer\prereqs\vc_redist.x64.exe  (Microsoft Visual C++ 2015-2022 Redistributable x64)'
}
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  if (-not (Test-Path (Join-Path $vcrtDir $dll))) { $missing += "installer\prereqs\vcruntime\$dll" }
}
if ($missing.Count -gt 0) {
  Fail ("Faltan prerrequisitos del instalador (vea installer\README.md):`n  - " + ($missing -join "`n  - "))
}

# --- Build ----------------------------------------------------------------
if (-not $SkipBuild) {
  $flutter = Find-Flutter
  Write-Host "Usando Flutter: $flutter"
  Push-Location $root
  try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { Fail 'flutter pub get falló.' }
    & $flutter build windows --release
    if ($LASTEXITCODE -ne 0) { Fail 'flutter build windows --release falló.' }
  } finally { Pop-Location }
}

# --- Verify build output ----------------------------------------------------
$required = @(
  'rmqbsync.exe',
  'flutter_windows.dll',
  'data\app.so',
  'data\icudtl.dat',
  'data\flutter_assets\AssetManifest.bin',
  'data\flutter_assets\assets\icons\app_icon.png',
  'flutter_secure_storage_windows_plugin.dll',
  'url_launcher_windows_plugin.dll'
)
$missing = @()
foreach ($f in $required) { if (-not (Test-Path (Join-Path $release $f))) { $missing += $f } }
if (-not (Get-ChildItem $release -Filter '*sqlite3*.dll' -ErrorAction SilentlyContinue)) { $missing += 'sqlite3.dll (bundled by package:sqlite3)' }
if (-not (Get-ChildItem $release -Filter '*nativeapi*.dll' -ErrorAction SilentlyContinue)) { $missing += 'nativeapi*.dll (window_manager / tray_manager)' }
if ($missing.Count -gt 0) {
  Fail ("La compilación no contiene archivos requeridos en ${release}:`n  - " + ($missing -join "`n  - "))
}
Write-Host 'Archivos de la compilación verificados:' -ForegroundColor Green
Get-ChildItem $release -Filter *.dll | ForEach-Object { Write-Host "  $($_.Name)" }

# --- Compile installer -------------------------------------------------------
$iscc = Find-Iscc
Write-Host "Usando ISCC: $iscc"
& $iscc "/DAppVersion=$Version" (Join-Path $installer 'RMQBsync.iss')
if ($LASTEXITCODE -ne 0) { Fail 'ISCC falló al compilar el instalador.' }

$out = Join-Path $installer 'output\RMQBsync-Setup.exe'
if (-not (Test-Path $out)) { Fail "No se generó $out" }
$size = [math]::Round((Get-Item $out).Length / 1MB, 1)
Write-Host ''
Write-Host "Instalador listo: $out ($size MB)" -ForegroundColor Green
