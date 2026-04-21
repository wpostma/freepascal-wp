# How to Build FreePascal from Source (Linux x86_64 and windows, mac tbd)

LINUX Version tested on Ubuntu 24.04 (Noble), March 2026.
Building FPC trunk (3.3.1) from the main branch.

WINDOWS version tested on Windows 11, using FPC trunk 3.3.1 main branch.


## Quick start

Linux

```bash
bash install-bootstrap.sh    # one-time: downloads FPC 3.2.2 to /opt
bash build.sh                 # builds trunk using locked-down PATH
```

Windows
```
  build.ps1
```

## How it works

The Linux build script uses three scripts that keep the bootstrap and trunk compilers strictly separated:

| Script | Purpose |
|--------|---------|
| `install-bootstrap.sh` | Downloads FPC 3.2.2 to `/opt/fpc-3.2.2` (idempotent) |
| `build.sh` | Builds trunk with a locked-down PATH (bootstrap only) |
| `uninstall-bootstrap.sh` | Removes FPC 3.2.2 from `/usr` (if installed there by mistake) |

### Why a locked-down PATH?

The `build.sh` script sets PATH to exactly:

```
/opt/fpc-3.2.2/bin:/usr/bin:/bin
```

This **excludes `/usr/local/bin`** so there is zero ambiguity about
which compiler performs the bootstrap. Without this, a previously-
installed trunk compiler in `/usr/local/bin/fpc` could end up
bootstrapping itself, which defeats the purpose of having a known-good
bootstrap version.

For windows, instead of a locked down path, we hard code the path requirement to c:\fpc\3.3.1 for the bootstrap binary installation location.

## Prerequisites

### System packages

LINUX Prerequisites

All of these were already present on a typical Ubuntu desktop install,
but install them if missing:

```bash
sudo apt install build-essential binutils gdb \
  libx11-dev libgtk2.0-dev libgpm-dev libncurses-dev
```

### Bootstrap compiler (FPC 3.2.2)

```bash
bash install-bootstrap.sh
```

This downloads the official FPC 3.2.2 tarball and installs it to
`/opt/fpc-3.2.2`. It's idempotent — if already installed, it prints
the version and exits.

**Why `/opt` and not `/usr`?** Installing to `/usr` scatters ~35
binaries and config files across system directories, making it hard
to remove and risking conflicts with the trunk compiler. `/opt` keeps
it self-contained. If you previously installed to `/usr` by mistake:

```bash
sudo bash uninstall-bootstrap.sh
```

### Quick smoke test

LINUX:
```bash
/opt/fpc-3.2.2/bin/fpc /tmp/hello.pas -o/tmp/hello && /tmp/hello
```

WINDOWS:
TBD

## Building

```bash
bash build.sh
```

This builds compiler, rtl, packages, and utils in order. The compiler
is bootstrapped in a multi-pass cycle (compile with bootstrap fpc,
recompile with itself, verify stability).

On a Ryzen workstation, `make all` completes in roughly 2-3 minutes.
The build log is written to `build.log` (~3500 lines).

**Note:** `-j$(nproc)` parallel builds are not recommended — the FPC
build system has internal ordering dependencies. The compiler cycle
itself is single-threaded.

### Verify the build

```bash
./compiler/ppcx64 -iV                          # should print 3.3.1
./compiler/ppcx64 /tmp/hello.pas -o/tmp/hello \
  -Fu./rtl/units/x86_64-linux/                 # compile with new RTL
/tmp/hello                                      # run it
```

You must pass `-Fu./rtl/units/x86_64-linux/` to point the newly-built
compiler at the newly-built RTL units (it doesn't have an fpc.cfg yet).

### LINUX: Command line Install to /usr/local

LINUX:
After building, install the trunk compiler for general use:

```bash
sudo PATH=/opt/fpc-3.2.2/bin:/usr/bin:/bin \
  make install INSTALL_PREFIX=/usr/local
sudo ln -sf /usr/local/lib/fpc/3.3.1/ppcx64 /usr/local/bin/ppcx64
```

Then generate the trunk compiler's config (so it finds its own units):

```bash
sudo mkdir -p /usr/local/lib/fpc/etc
/usr/local/bin/fpcmkcfg -d 'basepath=/usr/local/lib/fpc/$fpcversion' \
  | sudo tee /usr/local/lib/fpc/etc/fpc.cfg > /dev/null
```

Verify:

```bash
/usr/local/bin/fpc -iV   # should print 3.3.1
fpc /tmp/hello.pas -o/tmp/hello && /tmp/hello
```

## Windows installer

Build the installer for windows with package.ps1
Requires Innosetup 6 be installed.

## Troubleshooting

LINUX TIPS:

- **No FPC in Ubuntu 24.04 repos:** Use `install-bootstrap.sh` to get
  the bootstrap compiler from the official tarball.
- **`install.sh` fails with "Bad substitution":** The upstream script
  requires `bash`, not `sh`. The `install-bootstrap.sh` wrapper handles
  this automatically.
- **`make install` says "install is up to date":** Your cwd is wrong.
  Make sure you're in the source root. This happens if your shell
  drifted to `/tmp` after extracting the bootstrap tarball. The
  `build.sh` script avoids this by `cd`-ing to its own directory.
- **`The Makefile doesn't support target -`:** The Makefile queries
  `fpc -iVSPTPSOTO` to detect the compiler. If `fpc` is not on PATH
  (e.g. because `sudo` stripped it), this fails. Always pass PATH
  explicitly to sudo: `sudo PATH=... make ...`
- **`fpc` says "ppcx64 can't be executed":** After `make install`,
  create the symlink:
  `sudo ln -sf /usr/local/lib/fpc/3.3.1/ppcx64 /usr/local/bin/ppcx64`
- **Newly-built compiler can't find units:** Pass `-Fu` pointing to
  `./rtl/units/x86_64-linux/` until you run `make install`.
- **Build produces "error" grep hits in the log:** False positives from
  filenames and identifiers. A successful build ends with
  `Build > build-stamp.x86_64-linux`.

WINDOWS TROUBLESHOOTING:

TBD

## Build outputs

After a successful build:

| Artifact | Path |
|----------|------|
| Compiler binary | `compiler/ppcx64` (5.2 MB) |
| RTL units | `rtl/units/x86_64-linux/` |
| Utilities | `utils/*/bin/x86_64-linux/` |
| Build stamp | `build-stamp.x86_64-linux` |


LINUX: After `make install INSTALL_PREFIX=/usr/local`:

| Artifact | Path |
|----------|------|
| fpc driver | `/usr/local/bin/fpc` |
| ppcx64 compiler | `/usr/local/lib/fpc/3.3.1/ppcx64` |
| ppcx64 symlink | `/usr/local/bin/ppcx64` (create manually) |
| RTL units | `/usr/local/lib/fpc/3.3.1/units/x86_64-linux/` |

## Compiler configuration (fpc.cfg)

Each compiler has its **own** `fpc.cfg` under its own prefix. There is
deliberately **no** `/etc/fpc.cfg` — that causes cross-contamination
because both compilers read it.

| Compiler | Config file |
|----------|-------------|
| Bootstrap 3.2.2 | `/opt/fpc-3.2.2/lib/fpc/etc/fpc.cfg` |
| Trunk 3.3.1 | `/usr/local/lib/fpc/etc/fpc.cfg` |

The `fpc` binary searches: `~/.fpc.cfg`, then `<prefix>/lib/fpc/etc/fpc.cfg`,
then `/etc/fpc.cfg`. By placing the config in the prefix-specific path and
removing `/etc/fpc.cfg`, each compiler is fully self-contained.

### Regenerating configs

If you reinstall, regenerate the config with `fpcmkcfg`:

```bash
# For trunk at /usr/local:
/usr/local/bin/fpcmkcfg -d 'basepath=/usr/local/lib/fpc/$fpcversion' \
  | sudo tee /usr/local/lib/fpc/etc/fpc.cfg > /dev/null

# For bootstrap at /opt:
/opt/fpc-3.2.2/bin/fpcmkcfg -d 'basepath=/opt/fpc-3.2.2/lib/fpc/$fpcversion' \
  | sudo tee /opt/fpc-3.2.2/lib/fpc/etc/fpc.cfg > /dev/null
```

### Cleanup checklist

The bootstrap installer (`install.sh`) writes several files to `/etc`
that should be removed after you set up prefix-specific configs:

LINUX Cleanup:

```bash
sudo rm -f /etc/fpc.cfg
sudo rm -f /etc/fppkg.cfg
sudo rm -rf /etc/fppkg
```
WINDOWS Cleanup:
todo.

## Notes

- The source tree version is 3.3.1 (trunk/development).
- Required bootstrap version: 3.2.2 (set in `Makefile.fpc` line 23).
- Default build target matches the host: `x86_64-linux`.
  or, on windows x86_64-win
  

