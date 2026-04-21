# FPC Windows Packager Notes

## Scripts

- **`package.ps1`** — stages the compiler, bundles third-party tools, and drives the Inno Setup compiler.
- **`setup.iss`** — Inno Setup 6 script; compiled by `package.ps1` via `ISCC.exe`.

Run `package.ps1` after `build.ps1`. Pass `-SkipStage` to reuse an existing staging tree.

---

## Three-step process

1. **Stage** (`make distinstall`) — writes the FPC tree into a flat staging directory that mirrors the layout of `C:\FPC\3.2.2`.
2. **Bundle** — copies gdb, binutils, and (optionally) GNU tools from MSYS2 into the staging tree.
3. **Inno Setup** (`ISCC.exe`) — compiles `setup.iss` against the staging tree into a self-contained `.exe` installer.

---

## What ends up where

### `bin\x86_64-win64`  (the main 64-bit bin dir)

| Content | Source |
|---------|--------|
| `fpc.exe`, `ppcx64.exe`, `fpcmake.exe`, `fpcres.exe`, `h2pas.exe`, `fpdoc.exe`, `fppkg.exe`, `fpcmkcfg.exe` | `make distinstall` + explicit build |
| `gdb.exe` + its runtime DLLs | MSYS2 `mingw64\bin` (ntldd walks the dep tree) |
| `as.exe`, `ld.exe`, `ar.exe`, `ranlib.exe`, `nm.exe`, `strip.exe`, `objdump.exe`, `objcopy.exe`, `dlltool.exe`, `windres.exe`, `windmc.exe`, `addr2line.exe` | MSYS2 `mingw64\bin` |
| Runtime DLLs for all of the above | MSYS2 `mingw64\bin` (ntldd) |

### `bin\win32`  (32-bit bootstrap dir)

Everything from `C:\FPC\3.2.2\bin\i386-win32` is copied verbatim — no filtering.

Key files:
- `ppc386.exe` (i386 native compiler)
- `ppcrossx64.exe` (i386→x86_64 cross compiler)
- `fpc.exe`, `fpcmake.exe`
- **Also: 32-bit `make.exe`, `grep.exe`, `diff.exe`, `cp.exe`, `mv.exe`, `rm.exe`, binutils (`as.exe`, `ld.exe`, etc.)**

The old FPC 3.2.2 Windows distribution shipped these GNU tools alongside the compiler in the same directory. Because the bootstrap bundle copies *all* files from `BootstrapDir` without filtering, they land in `bin\win32` as well. They are 32-bit binaries that depend on the MSYS2 runtime DLLs that also shipped with FPC 3.2.2.

---

## The GNU tools confusion

There was originally a block in `package.ps1` to copy MSYS2 GNU tools (`make`, `grep`, `diff`, `cp`, `mv`, `rm`, `install`, `echo`, `date`, `mkdir`, `gcc`, `cpp`) and MSYS2 runtime DLLs (`msys-2.0.dll`, `msys-iconv-2.dll`, `msys-intl-8.dll`) from `$MsysDir\usr\bin` into `bin\x86_64-win64`.

That block had two bugs:

1. **`$SkipGnuTools` was never declared as a `param`.** It appeared in the `.SYNOPSIS` docstring but not in the `param()` block.
2. **The `if` condition was missing.** The block opened with a bare `{` instead of `if (-not $SkipGnuTools) {`. In PowerShell, `{ ... }` on its own is a scriptblock *literal* — it evaluates to a `[ScriptBlock]` object and is immediately discarded. The entire block was dead code and had never run.

### Investigation

When we saw 32-bit `make.exe` and binutils in `bin\win32`, the initial assumption was that 64-bit MSYS2 tools were being written to the wrong directory. PowerShell inspection of the actual binaries confirmed they are **32-bit** — they come from the FPC 3.2.2 bootstrap directory, not from MSYS2.

### Decision

Decided to **comment out** the MSYS2 GNU tools block entirely (wrapped in `<# ... #>`). The 32-bit tools coming from the bootstrap in `bin\win32` are sufficient and match what FPC 3.2.2 shipped. If 64-bit MSYS2 tools are ever needed in `bin\x86_64-win64`, the block is preserved and can be re-enabled.

The `SkipGnuTools` parameter and its docstring were left as-is (commented out with the block) rather than deleted, in case the block is re-enabled later.

---

## PATH setup (setup.iss)

Both `bin\x86_64-win64` and `bin\win32` are added to the system PATH (HKLM) at install time.

- Controlled by the `addtopath` task (checkbox, defaults to checked on first install via `checkedonce`).
- `NeedsAddPath()` Pascal function prevents duplicate entries on reinstall.
- Two `[Registry]` entries, one per directory, both using `{olddata}` to prepend.
- Uninstall: `CurUninstallStepChanged` surgically strips both entries from the PATH string using `StringChange`. It does **not** rely on registry flags for removal.

### `uninsdeletevalue` was removed

Both registry entries originally carried `Flags: preservestringtype uninsdeletevalue`. The `uninsdeletevalue` flag tells Inno Setup to delete the registry *value* (the entire PATH string) on uninstall — catastrophic. It was removed; the Pascal uninstall code handles PATH cleanup correctly.

---

## Parameters (package.ps1)

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `BootstrapDir` | `C:\FPC\3.2.2\bin\i386-win32` | 32-bit FPC used to drive `make distinstall` and placed in `bin\win32` |
| `MsysDir` | `C:\msys64` | MSYS2 root — source of binutils, gdb, ntldd |
| `CpuTarget` | `x86_64` | Target CPU |
| `OsTarget` | `win64` | Target OS |
| `StagingDir` | `fpc-dist\fpc-<ver>.x86_64-win64` | Where `make distinstall` writes output |
| `ZipDestDir` | `installer\archives\` | Output directory for the installer `.exe` |
| `InnoSetupDir` | `C:\Program Files (x86)\Inno Setup 6` | Inno Setup installation |
| `-SkipStage` | off | Skip `make distinstall`, reuse existing `StagingDir` |
| `-SkipZip` | off | Skip zip archive step |
| `-SkipInstaller` | off | Skip Inno Setup compilation |
| `-SkipGdb` | off | Skip bundling gdb |
| `-SkipBinutils` | off | Skip bundling binutils |
| `-SkipBootstrap32` | off | Skip copying bootstrap into `bin\win32` (installer will fail if skipped) |

---

## Staging layout expected by setup.iss

```
<StagingDir>\
  bin\x86_64-win64\     <- compiler, gdb, binutils, DLLs
  bin\win32\            <- FPC 3.2.2 bootstrap + 32-bit GNU tools
  units\x86_64-win64\   <- compiled RTL and packages
  fpmkinst\x86_64-win64\
  msg\
  doc\
  examples\
```

Source files (`rtl\*`, `packages\*`) are pulled directly from the source tree by `setup.iss` — they are not staged by `make distinstall`.
