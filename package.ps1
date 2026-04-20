<#
.SYNOPSIS
    Stage, archive, and package FPC trunk as a Windows installer.
.DESCRIPTION
    Three steps, each independently skippable:

      1. STAGE   -- runs 'make distinstall' into a flat staging tree
                    (mirrors the layout of C:\FPC\3.2.2)
      2. ZIP     -- compresses the staging tree to a .zip archive
      3. ISCC    -- compiles setup.iss into a self-contained .exe installer

    Expects the compiler to already be built (run build.ps1 first).

.PARAMETER BootstrapDir
    Bootstrap compiler bin directory.  Default: C:\FPC\3.2.2\bin\i386-win32
.PARAMETER MsysDir
    MSYS2 root.  Default: C:\msys64
.PARAMETER CpuTarget
    Target CPU.  Default: x86_64
.PARAMETER OsTarget
    Target OS.   Default: win64
.PARAMETER StagingDir
    Where 'make distinstall' writes its output.
    Default: <srcdir>\fpc-dist\fpc-<version>.x86_64-win64
.PARAMETER ZipDestDir
    Directory for the output .zip archive.  Default: <srcdir>
.PARAMETER InnoSetupDir
    Inno Setup 6 installation directory.
    Default: C:\Program Files (x86)\Inno Setup 6
.PARAMETER SkipStage
    Skip 'make distinstall' (use an existing StagingDir).
.PARAMETER SkipZip
    Skip zip archive creation.
.PARAMETER SkipInstaller
    Skip Inno Setup compilation.
.EXAMPLE
    .\package.ps1
.EXAMPLE
    .\package.ps1 -SkipStage -StagingDir C:\FPC\fpc-dist\fpc-3.3.1.x86_64-win64
#>
param(
    [string]$BootstrapDir  = 'C:\FPC\3.2.2\bin\i386-win32',
    [string]$MsysDir       = 'C:\msys64',
    [string]$CpuTarget     = 'x86_64',
    [string]$OsTarget      = 'win64',
    [string]$StagingDir    = '',
    [string]$ZipDestDir    = '',
    [string]$InnoSetupDir  = 'C:\Program Files (x86)\Inno Setup 6',
    [switch]$SkipStage,
    [switch]$SkipZip,
    [switch]$SkipInstaller
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SrcDir = $PSScriptRoot

# ---- helpers ----------------------------------------------------------------

function Assert-File([string]$Path, [string]$Hint) {
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Not found: $Path" -ForegroundColor Red
        if ($Hint) { Write-Host "       $Hint" -ForegroundColor Yellow }
        exit 1
    }
}

function To-Posix([string]$WinPath) {
    $p = $WinPath.Replace('\', '/')
    if ($p -match '^([A-Za-z]):(.*)') { return '/' + $Matches[1].ToLower() + $Matches[2] }
    return $p
}

# ---- version from built compiler --------------------------------------------

$TargetSuffix = "${CpuTarget}-${OsTarget}"
$PpcName      = if ($CpuTarget -eq 'x86_64') { 'ppcx64.exe' } else { 'ppc386.exe' }
$NewPpc       = Join-Path $SrcDir "compiler\$PpcName"
Assert-File $NewPpc "Run build.ps1 first to produce compiler\$PpcName"

$FpcVersion = (& $NewPpc -iV 2>&1).ToString().Trim()
Write-Host "FPC version  : $FpcVersion"
Write-Host "Target       : $TargetSuffix"

# ---- resolve directories ----------------------------------------------------

if (-not $StagingDir) {
    $StagingDir = Join-Path $SrcDir "fpc-dist\fpc-${FpcVersion}.${TargetSuffix}"
}
if (-not $ZipDestDir) {
    $ZipDestDir = Join-Path $SrcDir 'installer'
}
$null = New-Item -ItemType Directory -Path $ZipDestDir -Force

$ZipName = "fpc-${FpcVersion}.${TargetSuffix}.zip"
$ZipPath = Join-Path $ZipDestDir $ZipName

Write-Host "Staging dir  : $StagingDir"
Write-Host "Zip output   : $ZipPath"
Write-Host ''

# ---- preflight: MSYS2 (needed for stage step) -------------------------------

$BashExe = Join-Path $MsysDir 'usr\bin\bash.exe'
$MakeExe = Join-Path $MsysDir 'usr\bin\make.exe'

if (-not $SkipStage) {
    Assert-File (Join-Path $BootstrapDir 'fpc.exe') "Set -BootstrapDir or run install-bootstrap"
    Assert-File $BashExe                             "Install MSYS2 or set -MsysDir"
    Assert-File $MakeExe                             "pacman -S make  (in MSYS2)"
}

# ---- preflight: Inno Setup 6 ------------------------------------------------

$IsccExe = Join-Path $InnoSetupDir 'ISCC.exe'
$IssFile  = Join-Path $SrcDir 'setup.iss'

if (-not $SkipInstaller) {
    Assert-File $IsccExe "Install Inno Setup 6 or set -InnoSetupDir"
    Assert-File $IssFile "setup.iss must exist alongside package.ps1"
}

# ---- build environment (needed for stage and fpcmkcfg) ----------------------

$BinutilsSub  = if ($CpuTarget -eq 'x86_64') { 'mingw64\bin' } else { 'mingw32\bin' }
$BinutilsDir  = Join-Path $MsysDir $BinutilsSub
$MsysUsrBin   = Join-Path $MsysDir 'usr\bin'
$BuildPath    = "$(To-Posix $BootstrapDir):$(To-Posix $BinutilsDir):$(To-Posix $MsysUsrBin):/bin"
$FpcForMake   = "$(To-Posix $BootstrapDir)/fpc.exe"
$SrcPosix     = To-Posix $SrcDir

# =============================================================================
# STEP 1: STAGE (make distinstall)
# =============================================================================
if (-not $SkipStage) {
    Write-Host '--- Step 1: make distinstall ---' -ForegroundColor Cyan

    # Remove stale staging tree so we get a clean snapshot
    if (Test-Path $StagingDir) {
        Write-Host "Removing stale staging dir: $StagingDir"
        Remove-Item -Recurse -Force $StagingDir
    }
    $null = New-Item -ItemType Directory -Path $StagingDir -Force

    # Setting INSTALL_BASEDIR=INSTALL_PREFIX flattens the tree so the
    # output matches C:\FPC\3.2.2 layout (bin/x86_64-win64/, units/, msg/, doc/)
    # rather than the default Unix lib/fpc/VERSION/ nesting.
    $StagePosix = To-Posix $StagingDir

    $StageScript = @"
set -euo pipefail
export PATH='$BuildPath'
cd '$SrcPosix'
rm -f build-stamp.* base.build-stamp.*
make distinstall \
  FPC='$FpcForMake' \
  CPU_TARGET=$CpuTarget \
  OS_TARGET=$OsTarget \
  BUILDFULLNATIVE=1 \
  INSTALL_PREFIX='$StagePosix' \
  INSTALL_BASEDIR='$StagePosix'
"@

    Write-Host "Staging to: $StagingDir"
    & $BashExe --norc --noprofile -c $StageScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: make distinstall failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "Stage complete." -ForegroundColor Green
} else {
    Write-Host '--- Step 1: SKIPPED (--SkipStage) ---' -ForegroundColor DarkGray
    Assert-File $StagingDir "StagingDir does not exist; remove -SkipStage or set -StagingDir"
}

# ---- verify required utils are present in staging (must be built with UTILS=1) --

$BinDest = Join-Path $StagingDir "bin\$TargetSuffix"
$RequiredUtils = @('fpc.exe','ppcx64.exe','fpcmake.exe','fpcres.exe','h2pas.exe','fpdoc.exe','fppkg.exe')
$MissingUtils  = $RequiredUtils | Where-Object { -not (Test-Path (Join-Path $BinDest $_)) }
if ($MissingUtils) {
    Write-Host "ERROR: Required utils missing from staging bin ($BinDest):" -ForegroundColor Red
    $MissingUtils | ForEach-Object { Write-Host "  missing: $_" -ForegroundColor Red }
    Write-Host "       Run build.ps1 (which passes UTILS=1) before packaging." -ForegroundColor Yellow
    exit 1
}
Write-Host "All required utils present in staging." -ForegroundColor Green

# ---- fpcmkcfg (not installed by distinstall -- build and stage explicitly) --

$FpcmkcfgSrc = Join-Path $SrcDir 'utils\fpcmkcfg'
$FpcmkcfgExe = Join-Path $FpcmkcfgSrc 'fpcmkcfg.exe'

if (-not (Test-Path (Join-Path $BinDest 'fpcmkcfg.exe'))) {
    Write-Host "Building fpcmkcfg.exe ..."
    $BuildFpcmkcfg = @"
set -euo pipefail
export PATH='$BuildPath'
cd '$(To-Posix $FpcmkcfgSrc)'
fpc fpcmkcfg.pp
"@
    & $BashExe --norc --noprofile -c $BuildFpcmkcfg
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: fpcmkcfg build failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    if (-not (Test-Path $FpcmkcfgExe)) {
        Write-Host "ERROR: fpcmkcfg.exe not found after build" -ForegroundColor Red
        exit 1
    }
    Copy-Item $FpcmkcfgExe -Destination $BinDest -Force
    Write-Host "fpcmkcfg.exe staged to $BinDest" -ForegroundColor Green
} else {
    Write-Host "fpcmkcfg.exe already present in staging." -ForegroundColor DarkGray
}

# ---- RTL + packages source archive ------------------------------------------
# Include rtl/ always, plus packages/<name>/ for every unit dir that was staged.

$SrcZipName = "src_${FpcVersion}.zip"
$SrcZipPath = Join-Path $StagingDir $SrcZipName

if (-not (Test-Path $SrcZipPath)) {
    Write-Host "Creating RTL + packages source archive ..."

    # Collect: rtl/ always, plus packages/<name>/ for each staged unit dir
    $DirsToZip = [System.Collections.Generic.List[string]]::new()
    $DirsToZip.Add((Join-Path $SrcDir 'rtl'))

    $StagedUnitsDir = Join-Path $StagingDir "units\$TargetSuffix"
    foreach ($UnitDir in (Get-ChildItem $StagedUnitsDir -Directory)) {
        $PkgSrc = Join-Path $SrcDir "packages\$($UnitDir.Name)"
        if (Test-Path $PkgSrc) {
            $DirsToZip.Add($PkgSrc)
        }
    }

    Write-Host "  Including: $($DirsToZip.Count) source directories"
    Compress-Archive -Path $DirsToZip.ToArray() -DestinationPath $SrcZipPath -CompressionLevel Optimal
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Compress-Archive failed" -ForegroundColor Red
        exit 1
    }
    $SrcMB = [math]::Round((Get-Item $SrcZipPath).Length / 1MB, 1)
    Write-Host "Source archive: $SrcZipPath ($SrcMB MB)" -ForegroundColor Green
} else {
    Write-Host "Source archive already present: $SrcZipPath" -ForegroundColor DarkGray
}

Write-Host ''

# =============================================================================
# STEP 2: ZIP
# =============================================================================
if (-not $SkipZip) {
    Write-Host '--- Step 2: Create zip archive ---' -ForegroundColor Cyan

    if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }

    Compress-Archive -Path "$StagingDir\*" -DestinationPath $ZipPath
    $ZipMB = [math]::Round((Get-Item $ZipPath).Length / 1MB, 1)
    Write-Host "Archive: $ZipPath ($ZipMB MB)" -ForegroundColor Green
} else {
    Write-Host '--- Step 2: SKIPPED (--SkipZip) ---' -ForegroundColor DarkGray
}

Write-Host ''

# =============================================================================
# STEP 3: INNO SETUP
# =============================================================================
if (-not $SkipInstaller) {
    Write-Host '--- Step 3: Compile Inno Setup installer ---' -ForegroundColor Cyan

    $InstallerOut = Join-Path $ZipDestDir "fpc-${FpcVersion}.${TargetSuffix}-setup.exe"

    & $IsccExe `
        "/DStagingDir=$StagingDir" `
        "/DAppVersion=$FpcVersion" `
        "/DTargetSuffix=$TargetSuffix" `
        "/O$ZipDestDir" `
        "/Ffpc-${FpcVersion}.${TargetSuffix}-setup" `
        $IssFile

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: ISCC failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    if (Test-Path $InstallerOut) {
        $SetupMB = [math]::Round((Get-Item $InstallerOut).Length / 1MB, 1)
        Write-Host "Installer: $InstallerOut ($SetupMB MB)" -ForegroundColor Green
    } else {
        Write-Host "Installer written to $ZipDestDir" -ForegroundColor Green
    }
} else {
    Write-Host '--- Step 3: SKIPPED (--SkipInstaller) ---' -ForegroundColor DarkGray
}

Write-Host ''
Write-Host '=== Package complete ===' -ForegroundColor Green
