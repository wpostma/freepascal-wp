<#
.SYNOPSIS
    Build FreePascal Win64 from source on Windows using the Win32 (32 bit) 3.2.2 bootstrap compiler.
.DESCRIPTION
    Windows equivalent of build.sh.  Uses a locked-down PATH (bootstrap FPC +
    MSYS2 binutils/utils) and invokes GNU make through MSYS2 bash to avoid
    MSYS2 path-conversion issues in recipes.

    -------------------------------------------------------------------------
    CROSS-COMPILATION SITUATION (Win32 bootstrap -> Win64 output)
    -------------------------------------------------------------------------
    The FPC 3.2.2 bootstrap package for Windows ships only 32-bit i386-win32
    binaries: fpc.exe, ppc386.exe, and ppcrossx64.exe.  Even on a 64-bit
    machine there is no 64-bit bootstrap compiler in the standard release.

    To produce a 64-bit compiler we rely on ppcrossx64.exe -- an i386
    cross-compiler that compiles Pascal source and emits x86_64-win64 code.
    The build proceeds in two phases:

      Phase 1 (compiler cycle):
        ppcrossx64.exe compiles the compiler source -> ppcx64.exe
        ppcx64.exe is a genuine 64-bit Windows executable.

      Phase 2:
        ppcx64.exe compiles the RTL, packages, and utils for x86_64-win64.

    From a toolchain perspective this is a cross compile: the *build host*
    is i386-win32 (the bootstrap) even though the *machine* is x86_64-win64.

    -------------------------------------------------------------------------
    WHY BUILDFULLNATIVE=1 AND NOT UTILS=1
    -------------------------------------------------------------------------
    Two superficially similar make flags control utility-program building:

      UTILS=1           -- tells the top-level Makefile to include the utils/
                           directory in build and install passes.  Necessary
                           but not sufficient.

      BUILDFULLNATIVE=1 -- implies UTILS=1, and also suppresses the -scp flag
                           that every utils sub-Makefile adds to fpmake
                           invocations.

    The -scp flag means --skipcrossprograms.  fpmake.exe is itself a 32-bit
    i386-win32 binary (compiled from the bootstrap).  When fpmake is asked to
    build programs for x86_64-win64 it calls IsDifferentFromBuild(), which
    returns true because the target CPU/OS differs from fpmake's own build
    host.  With -scp active, fpmake silently skips every program target
    (TTarget of type program) -- unit packages compile normally, but none of
    the utility executables (fpcres.exe, h2pas.exe, fpdoc.exe, fppkg.exe,
    fpcmake.exe, fppkg.exe) are produced.  The build exits with code 0 and
    no error message, so the omission is invisible without checking staging.

    Setting BUILDFULLNATIVE=1 removes -scp, telling fpmake "this is a full
    native build regardless of what IsDifferentFromBuild() thinks".

    -------------------------------------------------------------------------
    BUILD-STAMP BEHAVIOUR
    -------------------------------------------------------------------------
    The top-level Makefile gates the entire bootstrap sequence behind a stamp
    file (build-stamp.<target>).  Once the stamp exists, 'make all' is a
    no-op: it prints "Nothing to be done for 'all'" and exits 0 without
    running any build steps -- including utils.  The stamp records only that
    *a* build completed, not which flags were active, so a stamp from a prior
    run without BUILDFULLNATIVE=1 looks identical to one from a full build.

    This script deletes the stamps before every run so the full recipe always
    executes and the stamp is recreated with the correct flags in effect.

.PARAMETER BootstrapDir
    Bootstrap compiler bin directory.
    Default: C:\FPC\3.2.2\bin\i386-win32
.PARAMETER MsysDir
    MSYS2 root directory.
    Default: C:\msys64
.PARAMETER CpuTarget
    Target CPU.  Default: x86_64.  Use 'i386' for a 32-bit compiler.
.PARAMETER OsTarget
    Target OS.   Default: win64.  Use 'win32' for a 32-bit compiler.
.PARAMETER Install
    Also run 'make install' after a successful build.
.PARAMETER InstallPrefix
    Installation prefix (used only with -Install).
    Default: C:\FPC\trunk
.EXAMPLE
    .\build.ps1
.EXAMPLE
    .\build.ps1 -CpuTarget i386 -OsTarget win32
.EXAMPLE
    .\build.ps1 -Install -InstallPrefix C:\FPC\trunk
#>
param(
    [string]$BootstrapDir  = 'C:\FPC\3.2.2\bin\i386-win32',
    [string]$MsysDir       = 'C:\msys64',
    [string]$CpuTarget     = 'x86_64',
    [string]$OsTarget      = 'win64',
    [switch]$Install,
    [string]$InstallPrefix = 'C:\FPC\trunk'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SrcDir = $PSScriptRoot

# ---- helpers ----------------------------------------------------------------

function Assert-File([string]$Path, [string]$Hint) {
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Required file not found: $Path" -ForegroundColor Red
        if ($Hint) { Write-Host "       $Hint" -ForegroundColor Yellow }
        exit 1
    }
}

# Convert a Windows absolute path to MSYS2 POSIX notation.
# e.g.  C:\foo\bar  ->  /c/foo/bar
function To-Posix([string]$WinPath) {
    $p = $WinPath.Replace('\', '/')
    if ($p -match '^([A-Za-z]):(.*)') {
        return '/' + $Matches[1].ToLower() + $Matches[2]
    }
    return $p
}

# ---- preflight: bootstrap FPC -----------------------------------------------

Assert-File (Join-Path $BootstrapDir 'fpc.exe') `
    "Install FPC 3.2.2 or pass -BootstrapDir <path>"

$FpcExe = Join-Path $BootstrapDir 'fpc.exe'
$FpcVer = (& $FpcExe -iV 2>&1).ToString().Trim()
Write-Host "Bootstrap compiler : $FpcExe ($FpcVer)"

# ---- preflight: MSYS2 -------------------------------------------------------

$BashExe = Join-Path $MsysDir 'usr\bin\bash.exe'
$MakeExe = Join-Path $MsysDir 'usr\bin\make.exe'

Assert-File $BashExe "Install MSYS2 from https://www.msys2.org or pass -MsysDir <path>"
Assert-File $MakeExe "Open an MSYS2 terminal and run: pacman -S make"

$MakeVer = (& $MakeExe --version 2>&1 | Select-Object -First 1).ToString().Trim()
Write-Host "GNU make           : $MakeExe ($MakeVer)"

# ---- preflight: binutils (mingw64 for x86_64, mingw32 for i386) -------------

$BinutilsSub = if ($CpuTarget -eq 'x86_64') { 'mingw64\bin' } else { 'mingw32\bin' }
$BinutilsDir = Join-Path $MsysDir $BinutilsSub
$AsExe       = Join-Path $BinutilsDir 'as.exe'
$LdExe       = Join-Path $BinutilsDir 'ld.exe'

$PkgHint = if ($CpuTarget -eq 'x86_64') {
    "pacman -S mingw-w64-x86_64-binutils"
} else {
    "pacman -S mingw-w64-i686-binutils"
}
Assert-File $AsExe "Open an MSYS2 terminal and run: $PkgHint"
Assert-File $LdExe "Open an MSYS2 terminal and run: $PkgHint"

$AsVer = (& $AsExe --version 2>&1 | Select-Object -First 1).ToString().Trim()
Write-Host "Assembler (as)     : $AsExe ($AsVer)"

Write-Host "Source directory   : $SrcDir"
Write-Host "Target             : $CpuTarget-$OsTarget"
Write-Host ''

# ---- build environment (POSIX paths for bash/make) --------------------------

$SrcPosix       = To-Posix $SrcDir
$BootstrapPosix = To-Posix $BootstrapDir
$BinutilsPosix  = To-Posix $BinutilsDir
$MsysUsrPosix   = To-Posix (Join-Path $MsysDir 'usr\bin')
$FpcForMake     = "${BootstrapPosix}/fpc.exe"

# Locked-down PATH: bootstrap first (owns fpc/ppc386/ppcrossx64),
# then target binutils (as/ld for generated code), then MSYS2 utils
# (cp, mv, mkdir, sed, etc. used by Makefile recipes).
$BuildPath = "${BootstrapPosix}:${BinutilsPosix}:${MsysUsrPosix}:/bin"

Write-Host "Build PATH: $BuildPath"
Write-Host ''

# ---- invoke build via MSYS2 bash --------------------------------------------
# We go through bash so that Makefile recipes (cp, mkdir, sed, etc.) resolve
# against the controlled PATH rather than whatever PowerShell has set.

$BuildScript = @"
set -euo pipefail
export PATH='$BuildPath'
echo "which fpc  : `$(which fpc)"
echo "which as   : `$(which as)"
echo "which ld   : `$(which ld)"
echo "which make : `$(which make)"
echo ""
cd '$SrcPosix'
rm -f build-stamp.* base.build-stamp.*
make all FPC='$FpcForMake' CPU_TARGET=$CpuTarget OS_TARGET=$OsTarget BUILDFULLNATIVE=1 2>&1 | tee build.log

echo ""
echo "=== Build complete ==="
"@

Write-Host "Invoking make via MSYS2 bash ..."
& $BashExe --norc --noprofile -c $BuildScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed (exit $LASTEXITCODE). See $SrcDir\build.log" -ForegroundColor Red
    exit $LASTEXITCODE
}

# ---- report new compiler ----------------------------------------------------

$PpcName = if ($CpuTarget -eq 'x86_64') { 'ppcx64.exe' } else { 'ppc386.exe' }
$NewPpc  = Join-Path $SrcDir "compiler\$PpcName"

if (Test-Path $NewPpc) {
    $NewVer = (& $NewPpc -iV 2>&1).ToString().Trim()
    Write-Host "New compiler backend   : $NewPpc ($NewVer)"
} else {
    Write-Host "Note: $NewPpc not found -- check build.log" -ForegroundColor Yellow
}
Write-Host "New compiler bootstrap : $FpcExe ($FpcVer)  (fpc.exe driver, unchanged from bootstrap)"
Write-Host "Build log              : $SrcDir\build.log"

# ---- optional install -------------------------------------------------------

if ($Install) {
    Write-Host ''
    Write-Host "Installing to $InstallPrefix ..."
    $InstallPosix = To-Posix $InstallPrefix

    $InstallScript = @"
set -euo pipefail
export PATH='$BuildPath'
cd '$SrcPosix'
make install INSTALL_PREFIX='$InstallPosix' FPC='$FpcForMake' CPU_TARGET=$CpuTarget OS_TARGET=$OsTarget
"@

    & $BashExe --norc --noprofile -c $InstallScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Install failed (exit $LASTEXITCODE)." -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "Installed to $InstallPrefix"
}
