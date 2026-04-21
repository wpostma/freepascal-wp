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
.PARAMETER SkipGdb
    Skip bundling gdb.exe and its runtime DLLs.  By default the script
    copies gdb.exe and every non-system DLL it depends on from the MSYS2
    mingw64 tree into the staging bin directory so the installer ships a
    self-contained debugger.  Pass -SkipGdb to omit this step (e.g. for
    a compiler-only package or when gdb is not installed in MSYS2).
.PARAMETER SkipBinutils
    Skip bundling the mingw64 binutils (as.exe, ld.exe, ar.exe, etc.).
    Without these tools the installed FPC cannot assemble or link anything.
    They are omitted only if you intend to rely on binutils already on the
    end-user PATH.
.PARAMETER SkipGnuTools
    Skip bundling GNU/MSYS2 tools (make, grep, diff, cp, mv, rm, pwd, cmp,
    gcc, cpp, ginstall, gecho, gdate, gmkdir) and the MSYS2 runtime DLLs
    (msys-2.0.dll, msys-iconv-2.dll, msys-intl-8.dll).  These tools match
    the historical FPC 3.2.2 Windows distribution and are useful for
    Makefile-based projects.
.PARAMETER SkipBootstrap32
    Skip bundling the FPC 3.2.2 i386-win32 bootstrap compiler into
    bin\win32.  By default package.ps1 copies ppc386.exe, ppcrossx64.exe,
    fpc.exe, fpcmake.exe and all other files from BootstrapDir into a
    bin\win32 subdirectory so users can rebuild the compiler from source
    without a separate FPC 3.2.2 installation.  Note: setup.iss expects
    this directory to exist; the installer compile will fail if you skip
    this step without also removing the [Files] entry for bin\win32.
.EXAMPLE
    .\package.ps1
.EXAMPLE
    .\package.ps1 -SkipStage -StagingDir C:\FPC\fpc-dist\fpc-3.3.1.x86_64-win64
.EXAMPLE
    .\package.ps1 -SkipGdb
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
    [switch]$SkipInstaller,
    [switch]$SkipGdb,
    [switch]$SkipBinutils,
    [switch]$SkipGnuTools,
    [switch]$SkipBootstrap32
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

# =============================================================================
# GDB BUNDLE
# =============================================================================
# Copy gdb.exe and every mingw64 runtime DLL it requires from the local MSYS2
# installation into the staging bin directory.  setup.iss picks them up
# automatically via the existing {#BinDir}\* wildcard -- no ISS changes needed.
#
# We use ntldd -R (recursive ldd for Windows) to find the full transitive DLL
# closure, then filter to mingw64 paths only (skipping Windows system DLLs).
# The DLL filenames are extracted and looked up in the mingw64\bin directory,
# which avoids any sensitivity to MSYS2 path notation in ntldd output.

$GdbSrc  = Join-Path $MsysDir 'mingw64\bin\gdb.exe'
$NtlddExe = Join-Path $MsysDir 'usr\bin\ntldd.exe'

if ($SkipGdb) {
    Write-Host '--- GDB bundle: SKIPPED (-SkipGdb) ---' -ForegroundColor DarkGray
} elseif (-not (Test-Path $GdbSrc)) {
    Write-Host 'WARNING: gdb.exe not found -- skipping GDB bundle.' -ForegroundColor Yellow
    Write-Host "         Run in MSYS2: pacman -S mingw-w64-x86_64-gdb" -ForegroundColor Yellow
} elseif (-not (Test-Path $NtlddExe)) {
    Write-Host 'WARNING: ntldd.exe not found -- skipping GDB bundle.' -ForegroundColor Yellow
    Write-Host "         Run in MSYS2: pacman -S ntldd" -ForegroundColor Yellow
} else {
    Write-Host '--- Bundling GDB + runtime DLLs ---' -ForegroundColor Cyan

    $GdbSrcPosix  = To-Posix $GdbSrc
    $Mingw64Posix = To-Posix (Join-Path $MsysDir 'mingw64\bin')
    $MsysUsrPosix = To-Posix (Join-Path $MsysDir 'usr\bin')

    # Run ntldd -R, filter to mingw64 lines, extract just the DLL filename.
    # Using basename avoids any dependency on MSYS2 vs Windows path notation.
    $NtlddScript = @"
export PATH='$($Mingw64Posix):$($MsysUsrPosix):/bin'
ntldd -R '$GdbSrcPosix' \
  | grep -i 'mingw64' \
  | sed 's/.*=> //' \
  | sed 's/ (0x[0-9a-fA-F]*).*//' \
  | xargs -I{} basename '{}' \
  | tr -d '\r' \
  | sort -u
"@

    $DllNames = (& $BashExe --norc --noprofile -c $NtlddScript) -split "`n" |
                Where-Object { $_.Trim() -ne '' }

    Copy-Item $GdbSrc -Destination $BinDest -Force
    Write-Host '  gdb.exe'

    $Copied = 0
    foreach ($dll in $DllNames) {
        $src = Join-Path $MsysDir "mingw64\bin\$dll"
        if (Test-Path $src) {
            Copy-Item $src -Destination $BinDest -Force
            Write-Host "  $dll"
            $Copied++
        }
    }

    Write-Host "GDB bundled: gdb.exe + $Copied runtime DLLs." -ForegroundColor Green
}

Write-Host ''

# =============================================================================
# BINUTILS BUNDLE
# =============================================================================
# as.exe and ld.exe are called by FPC for every compile -- without them the
# installed compiler cannot produce output.  The full set below covers every
# tool a Pascal developer is likely to need (resource compiler, archiver,
# symbol listing, disassembler, etc.).  Binutils DLL deps are a small subset
# of gdb's, so most DLLs will already be present after the GDB step.

$BinutilsExes = @(
    'as.exe',       # assembler         -- required by FPC
    'ld.exe',       # linker            -- required by FPC
    'ar.exe',       # static-lib archiver
    'ranlib.exe',   # archive indexer
    'nm.exe',       # symbol listing
    'strip.exe',    # strip debug info
    'objdump.exe',  # disassembler / object inspector
    'objcopy.exe',  # object file conversion
    'dlltool.exe',  # import-library generator
    'windres.exe',  # Windows resource compiler
    'windmc.exe',   # Windows message compiler
    'addr2line.exe' # address -> source line (debugger support)
)

if ($SkipBinutils) {
    Write-Host '--- Binutils bundle: SKIPPED (-SkipBinutils) ---' -ForegroundColor DarkGray
} else {
    Write-Host '--- Bundling binutils ---' -ForegroundColor Cyan

    $Mingw64Bin = Join-Path $MsysDir 'mingw64\bin'

    # Collect paths of all present binutils exes for the ntldd pass.
    $PresentExes   = $BinutilsExes | ForEach-Object { Join-Path $Mingw64Bin $_ } |
                     Where-Object  { Test-Path $_ }
    $MissingBinutils = $BinutilsExes | Where-Object { -not (Test-Path (Join-Path $Mingw64Bin $_)) }

    if ($MissingBinutils) {
        Write-Host "WARNING: some binutils not found in $Mingw64Bin -- skipping those:" -ForegroundColor Yellow
        $MissingBinutils | ForEach-Object { Write-Host "  missing: $_" -ForegroundColor Yellow }
        Write-Host "         Run in MSYS2: pacman -S mingw-w64-x86_64-binutils" -ForegroundColor Yellow
    }

    # Copy the executables.
    foreach ($exe in $PresentExes) {
        Copy-Item $exe -Destination $BinDest -Force
        Write-Host "  $(Split-Path $exe -Leaf)"
    }

    # Find DLL deps across all binutils in one ntldd pass.
    if ($PresentExes -and (Test-Path $NtlddExe)) {
        $ExePosixList = ($PresentExes | ForEach-Object { "'$(To-Posix $_)'" }) -join ' '
        $Mingw64Posix2 = To-Posix $Mingw64Bin
        $MsysUsrPosix2 = To-Posix (Join-Path $MsysDir 'usr\bin')

        $BinutilsDllScript = @"
export PATH='$($Mingw64Posix2):$($MsysUsrPosix2):/bin'
for exe in $ExePosixList; do
  ntldd -R "`$exe" 2>/dev/null | grep -i 'mingw64' | sed 's/.*=> //' | sed 's/ (0x[0-9a-fA-F]*).*//' | xargs -I{} basename '{}'
done | tr -d '\r' | sort -u
"@
        $BinutilsDlls = (& $BashExe --norc --noprofile -c $BinutilsDllScript) -split "`n" |
                        Where-Object { $_.Trim() -ne '' }

        $DllsCopied = 0
        foreach ($dll in $BinutilsDlls) {
            $src = Join-Path $Mingw64Bin $dll
            if (Test-Path $src) {
                Copy-Item $src -Destination $BinDest -Force
                $DllsCopied++
            }
        }
        if ($DllsCopied) { Write-Host "  + $DllsCopied runtime DLLs" }
    }

    Write-Host "Binutils bundled: $($PresentExes.Count) executables." -ForegroundColor Green
}

Write-Host ''

# =============================================================================
# GNU TOOLS BUNDLE
# =============================================================================
# Copy classic GNU tools from MSYS2 into the staging bin directory to match
# the layout of the old FPC 3.2.2 Windows distribution.  These tools let
# Makefile-based projects build without a separate MSYS2 install on PATH.
#
# usr/bin tools need the MSYS2 runtime layer (msys-2.0.dll etc.).
# The g-prefixed tools are renamed copies per FPC naming convention.
# gcc and cpp come from mingw64 and share DLLs already copied by binutils.

$GnuToolsCopy = @(
    @{ Src = 'usr\bin\make.exe';    Dst = 'make.exe'     },
    @{ Src = 'usr\bin\grep.exe';    Dst = 'grep.exe'     },
    @{ Src = 'usr\bin\diff.exe';    Dst = 'diff.exe'     },
    @{ Src = 'usr\bin\cp.exe';      Dst = 'cp.exe'       },
    @{ Src = 'usr\bin\mv.exe';      Dst = 'mv.exe'       },
    @{ Src = 'usr\bin\rm.exe';      Dst = 'rm.exe'       },
    @{ Src = 'usr\bin\pwd.exe';     Dst = 'pwd.exe'      },
    @{ Src = 'usr\bin\cmp.exe';     Dst = 'cmp.exe'      },
    @{ Src = 'usr\bin\install.exe'; Dst = 'ginstall.exe' },
    @{ Src = 'usr\bin\echo.exe';    Dst = 'gecho.exe'    },
    @{ Src = 'usr\bin\date.exe';    Dst = 'gdate.exe'    },
    @{ Src = 'usr\bin\mkdir.exe';   Dst = 'gmkdir.exe'   },
    @{ Src = 'mingw64\bin\gcc.exe'; Dst = 'gcc.exe'      },
    @{ Src = 'mingw64\bin\cpp.exe'; Dst = 'cpp.exe'      }
)
$MsysRuntimeDlls = @('msys-2.0.dll', 'msys-iconv-2.dll', 'msys-intl-8.dll')

if ($SkipGnuTools) {
    Write-Host '--- GNU tools bundle: SKIPPED (-SkipGnuTools) ---' -ForegroundColor DarkGray
} else {
    Write-Host '--- Bundling GNU tools ---' -ForegroundColor Cyan

    $GnuCopied = 0
    foreach ($tool in $GnuToolsCopy) {
        $src = Join-Path $MsysDir $tool.Src
        if (Test-Path $src) {
            Copy-Item $src -Destination (Join-Path $BinDest $tool.Dst) -Force
            Write-Host "  $(Split-Path $tool.Src -Leaf) -> $($tool.Dst)"
            $GnuCopied++
        } else {
            Write-Host "  SKIP (not found): $($tool.Src)" -ForegroundColor DarkGray
        }
    }

    foreach ($dll in $MsysRuntimeDlls) {
        $src = Join-Path $MsysDir "usr\bin\$dll"
        if (Test-Path $src) {
            Copy-Item $src -Destination $BinDest -Force
            Write-Host "  $dll"
        } else {
            Write-Host "  SKIP (not found): $dll" -ForegroundColor DarkGray
        }
    }

    Write-Host "GNU tools bundled: $GnuCopied executables." -ForegroundColor Green
}

Write-Host ''

# =============================================================================
# BOOTSTRAP WIN32 BUNDLE (bin\win32)
# =============================================================================
# Ship the FPC 3.2.2 i386-win32 bootstrap compiler in bin\win32 so users
# can rebuild the compiler from source without a separate 3.2.2 installation.
# Key files: ppc386.exe (i386 native), ppcrossx64.exe (i386->x86_64 cross),
# fpc.exe (driver), fpcmake.exe.  All files in BootstrapDir are copied.

$Win32BinDest = Join-Path $StagingDir 'bin\win32'

if ($SkipBootstrap32) {
    Write-Host '--- Bootstrap win32 bundle: SKIPPED (-SkipBootstrap32) ---' -ForegroundColor DarkGray
    Write-Host '    NOTE: setup.iss expects bin\win32; installer compile will fail.' -ForegroundColor Yellow
} elseif (-not (Test-Path $BootstrapDir)) {
    Write-Host "WARNING: Bootstrap dir not found ($BootstrapDir) -- skipping win32 bundle." -ForegroundColor Yellow
    Write-Host "         NOTE: setup.iss expects bin\win32; installer compile will fail." -ForegroundColor Yellow
} else {
    Write-Host '--- Bundling 3.2.2 bootstrap into bin\win32 ---' -ForegroundColor Cyan

    $null = New-Item -ItemType Directory -Path $Win32BinDest -Force

    $Win32Count = 0
    foreach ($f in (Get-ChildItem $BootstrapDir -File)) {
        Copy-Item $f.FullName -Destination $Win32BinDest -Force
        $Win32Count++
    }

    Write-Host "Bootstrap win32: $Win32Count files -> $Win32BinDest" -ForegroundColor Green
}

Write-Host ''

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
