# One-click setup for the Space Bucks static recompilation.
# Run it by double-clicking Setup.cmd in the repo folder; the README's "Step by
# step" is the same thing by hand, command for command.
#
# It checks the tools, finds your CD (or a folder or .iso of it), copies the
# game into game\, lifts it to C (work\), builds build\spacebucks.exe with MinGW gcc
# and leaves a shortcut. Each step is skipped when its output already exists
# (-Force redoes them). Everything it does goes to setup.log. Nothing of the
# game is downloaded: it only reads your copy.
param([switch]$Force, [switch]$Yes, [string]$GameDir = "")

# ---------------------------------------------------------------- this game
$Title     = 'Space Bucks'
$Exe       = 'spacebucks.exe'
$Branch    = 'main'
$Shortcut  = 'Space Bucks.cmd'
$NeedMB    = 700
# A folder holds the game when it is the CD: HD\SPACEBUC.EXE beside DATA, VIDEO and WAV.
function Is-Source([string]$d) { return ($d -and (Test-Path (Join-Path $d 'HD\SPACEBUC.EXE'))) }
# The CD's HD folder is the installed game; DATA, VIDEO and WAV merge into it
# (game\DATA gets both halves). The game asks its INI for the CD drive.
function Copy-Game([string]$src) {
  foreach ($p in @(@('HD', 'game'), @('DATA', 'game\DATA'), @('VIDEO', 'game\VIDEO'), @('WAV', 'game\WAV'))) {
    $from = Join-Path $src $p[0]
    if (-not (Test-Path $from)) { Fail "$from is missing: is this the Space Bucks CD?" }
    $code = Exec @('robocopy', $from, $p[1], '/E', '/NFL', '/NDL', '/NJH', '/NJS', '/R:1', '/W:1')
    if ($code -ge 8) { Fail "copying $from failed (robocopy code $code)." }
  }
  Get-ChildItem game -Recurse -File | ForEach-Object { $_.IsReadOnly = $false }   # files off a CD are read-only
  if (-not (Test-Path 'game\SPACEBUC.INI')) { Set-Content -Path 'game\SPACEBUC.INI' -Encoding ASCII -Value @('[Config]', 'CDDRIVE=D:') }
}
$GameMarker = 'game\SPACEBUC.EXE'
# ----------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Parent = Split-Path -Parent $Root
$Toolkit = if ($env:PCRECOMP_DIR) { $env:PCRECOMP_DIR } else { Join-Path $Parent 'pcrecomp' }
$Log = Join-Path $Root 'setup.log'
Set-Location $Root
function Log($t) { try { Add-Content -Path $Log -Value $t -Encoding UTF8 -ErrorAction Stop } catch {} }
Log "==== setup $(Get-Date -Format s)"

function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; Log $t }
function Step($n, $t) { Write-Host ""; Say "[$n/6] $t" 'Cyan' }
function Pause-End { if (-not $env:RECOMP_LAUNCHER -and -not $Yes) { Read-Host "Press Enter to close" | Out-Null } }
function Fail($t) {
  Say "" ; Say "Setup stopped: $t" 'Red'
  Say "The details are in $Log. Fix that and run Setup.cmd again; finished steps are skipped." 'Yellow'
  Pause-End; exit 1
}
function Ask($q) { if ($Yes) { Say "$q yes"; return $true }; $a = Read-Host "$q [Y/n]"; return -not ($a -match '^[nN]') }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
# Run a program with its output in the log. Windows PowerShell turns a native
# program's stderr into errors, so 'Stop' is off while it runs.
function Exec([string[]]$cmd) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $rest = @($cmd | Select-Object -Skip 1)
  & $cmd[0] @rest 2>&1 | ForEach-Object { Log "$_" }
  $code = $LASTEXITCODE
  $ErrorActionPreference = $old
  return $code
}
function Run($what, [string[]]$cmd) {
  Say "  $what..."
  $code = Exec $cmd
  if ($code -ne 0) { Fail "$what failed (exit code $code)." }
}
function Winget($id, $what) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail "winget is missing. Install 'App Installer' from the Microsoft Store, or install $what yourself." }
  Exec @('winget', 'install', '-e', '--id', $id, '--accept-package-agreements', '--accept-source-agreements') | Out-Null
  Refresh-Path
}

if (-not $Yes) { Clear-Host }
Say "$Title - static recompilation setup" 'White'
Say "You need your own copy of the game and about $NeedMB MB free. Nothing of the game is downloaded."

# ---------------------------------------------------------------- tools
Step 1 "Checking the tools the pipeline needs"
function Find-Python {
  foreach ($c in @(@('py', '-3'), @('python'), @('python3'))) {
    if (-not (Get-Command $c[0] -ErrorAction SilentlyContinue)) { continue }
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $rest = @($c | Select-Object -Skip 1)
    $v = (& $c[0] @rest --version 2>&1 | Out-String).Trim()
    $ErrorActionPreference = $old
    if ($v -match '^Python 3\.(\d+)' -and [int]$Matches[1] -ge 10) { return ,$c }
  }
  return $null
}
$pyargs = Find-Python
if (-not $pyargs) {
  Say "  Python 3.10 or newer is not installed."
  if (-not (Ask "  Install Python 3.12 now (winget, about 30 MB)?")) { Fail "Python 3 is required." }
  Winget 'Python.Python.3.12' 'Python'
  $pyargs = Find-Python
  if (-not $pyargs) { Fail "Python installed, but Windows has not picked it up yet: close this window and run Setup.cmd again." }
}
Say "  Python: $($pyargs -join ' ')"
if ((Exec ($pyargs + @('-c', 'import capstone'))) -ne 0) {
  Say "  The Python package capstone is missing (about 10 MB)."
  if (-not (Ask "  Install it now (pip, for your user only)?")) { Fail "capstone is required." }
  Run "Installing capstone" ($pyargs + @('-m', 'pip', 'install', '--user', 'capstone'))
}
foreach ($tool in @(@('cmake', 'Kitware.CMake', '30 MB'), @('ninja', 'Ninja-build.Ninja', '1 MB'))) {
  if (Get-Command $tool[0] -ErrorAction SilentlyContinue) { continue }
  Say "  $($tool[0]) is not installed."
  if (-not (Ask "  Install $($tool[0]) now (winget, about $($tool[2]))?")) { Fail "$($tool[0]) is required." }
  Winget $tool[1] $tool[0]
  if (-not (Get-Command $tool[0] -ErrorAction SilentlyContinue)) { Fail "$($tool[0]) installed, but Windows has not picked it up yet: close this window and run Setup.cmd again." }
}
# MinGW-w64 gcc (MSYS2). The host and the lifted C are built with gcc: the
# CMake file uses GNU flags (-O2 sibling calls, a 256 MB stack, no ASLR).
$Gcc = 'C:\msys64\mingw64\bin\gcc.exe'
if (-not (Test-Path $Gcc)) {
  $g = Get-Command gcc -ErrorAction SilentlyContinue
  if ($g) { $Gcc = $g.Source }
}
if (-not (Test-Path $Gcc)) {
  Say "  MinGW-w64 gcc is not installed."
  if (-not (Ask "  Install MSYS2 and its mingw64 gcc now (winget then pacman, about 1 GB)?")) { Fail "MinGW-w64 gcc is required." }
  Winget 'MSYS2.MSYS2' 'MSYS2'
  if (-not (Test-Path 'C:\msys64\usr\bin\bash.exe')) { Fail "MSYS2 did not install to C:\msys64. Install it from msys2.org, then run Setup.cmd again." }
  Run "Installing gcc" @('C:\msys64\usr\bin\bash.exe', '-lc', 'pacman -S --needed --noconfirm mingw-w64-x86_64-gcc')
  $Gcc = 'C:\msys64\mingw64\bin\gcc.exe'
  if (-not (Test-Path $Gcc)) { Fail "gcc is still missing from C:\msys64\mingw64\bin. Open MSYS2 and run: pacman -S mingw-w64-x86_64-gcc" }
}
Say "  gcc: $Gcc"
if (-not (Test-Path (Join-Path $Toolkit 'tools\ne\ne_link.py'))) {
  Say "  The pcrecomp toolkit is not beside this folder ($Toolkit)."
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "git is needed to fetch pcrecomp. Install Git for Windows, then run Setup.cmd again." }
  if (-not (Ask "  Download it now (git, branch $Branch, about 50 MB)?")) { Fail "pcrecomp is required at $Toolkit." }
  Run "Cloning pcrecomp" @('git', 'clone', '--depth', '1', '-b', $Branch, 'https://github.com/sp00nznet/pcrecomp', $Toolkit)
}
# An existing checkout is the user's: say what is wrong, never switch it.
$cur = (& git -C $Toolkit branch --show-current 2>$null)
if ($cur -and $cur -ne $Branch) {
  Fail "your pcrecomp at $Toolkit is on branch '$cur'; this game needs '$Branch'. Run: git -C `"$Toolkit`" checkout $Branch (or set PCRECOMP_DIR to a checkout of it)."
}
Say "  pcrecomp: $Toolkit"

# ---------------------------------------------------------------- the game
Step 2 "Finding your copy of the game"
if ((Test-Path $GameMarker) -and -not $Force) { Say "  Already in game\ (skipping)." }
else {
  $src = $GameDir.Trim('"', ' ')
  if ($src -match '\.iso$' -and (Test-Path $src)) {
    $img = Mount-DiskImage -ImagePath (Resolve-Path $src).Path -PassThru
    $src = (($img | Get-Volume).DriveLetter + ':\')
    Say "  Mounted the image as $src"
  }
  if (-not (Is-Source $src)) {
    $src = ""
    foreach ($d in (Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Root })) { if (Is-Source $d) { $src = $d; break } }
    if ($src) { Say "  Found it in $src" }
  }
  if (-not (Is-Source $src) -and ($Yes -or $env:RECOMP_LAUNCHER)) { Fail "the game was not found. Run Setup.cmd -GameDir <the CD's drive or folder>." }
  while (-not (Is-Source $src)) {
    $src = (Read-Host "  Paste the drive or folder holding the game (the CD, a copy of it, or a mounted .iso)").Trim('"', ' ')
    if (-not (Is-Source $src)) { Say "  The game is not in that folder." 'Yellow' }
  }
  Say "  Copying the game from $src into game\..."
  New-Item -ItemType Directory -Force game | Out-Null
  Copy-Game $src
}

# ---------------------------------------------------------------- lift
Step 3 "Lifting the game to C (a few minutes)"
if ((Test-Path 'work\mem_image.bin') -and -not $Force) { Say "  Already done (skipping)." }
else {
  $env:PCRECOMP_DIR = $Toolkit
  $relift = @('tools\relift.py')
  Run "Lifting" ($pyargs + $relift)
}

# ---------------------------------------------------------------- build
Step 4 "Configuring the build"
# gcc needs its own bin folder on PATH for cc1, as and ld.
$env:Path = (Split-Path -Parent $Gcc) + ';' + $env:Path
if ((Test-Path 'build\build.ninja') -and -not $Force) { Say "  Already done (skipping)." }
else {
  Run "Configuring" @('cmake', '-S', '.', '-B', 'build', '-G', 'Ninja', "-DCMAKE_C_COMPILER=$($Gcc -replace '\\','/')", "-DPCRECOMP_DIR=$($Toolkit -replace '\\','/')")
}
Step 5 "Building build\$Exe (several minutes)"
# Always runs: Ninja makes it seconds when nothing changed.
Run "Compiling" @('cmake', '--build', 'build')

# ---------------------------------------------------------------- shortcut
Step 6 "Making the shortcut"
$lnk = Join-Path $Root $Shortcut
Set-Content -Path $lnk -Encoding ASCII -Value @('@echo off', 'cd /d "%~dp0"', "build\$Exe")
Say "  $lnk"
Write-Host ""
Say "Done. Double-click '$Shortcut' to run it." 'Green'
Say "This is an early build: README.md, Status, says how far it gets."
Pause-End
