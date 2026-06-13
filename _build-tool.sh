#!/bin/bash
#
# _build-tool.sh — shared helpers for the FreePascal build scripts.
#
# This file is meant to be *sourced*, not executed directly:
#
#     source "${SRCDIR}/_build-tool.sh"
#
# It is the single source of truth for the shell builds (build-linux.sh,
# build-mac.sh, rebuild-fcl.sh).  build.sh is a thin dispatcher that picks
# the right per-platform script.  Windows has its own build.ps1.
#
# Caller contract (set before calling the functions):
#   SRCDIR              - absolute path to the source tree root (required)
#   OS_TARGET           - "linux" | "darwin"   (required for build summary)
#   BT_LEGACY_FALLBACK  - optional path to a fallback fpc binary
#
# -------------------------------------------------------------------------
# CROSS-COMPILATION SITUATION (Win32 bootstrap -> Win64 output)
# -------------------------------------------------------------------------
# The primary build target on Windows is x86_64-win64: a full set of
# 64-bit Windows compiler binaries and utility programs (ppcx64.exe,
# fpcres.exe, h2pas.exe, fpdoc.exe, fppkg.exe, fpcmake.exe, etc.).
#
# On Windows the only available FPC 3.2.2 bootstrap package ships 32-bit
# i386-win32 binaries.  Even on a 64-bit machine there is no 64-bit
# bootstrap compiler in the standard release.  The build therefore proceeds
# as a pseudo-cross compile:
#
#   Build host:  i386-win32  (the 32-bit bootstrap binaries)
#   Target:      x86_64-win64 (the 64-bit output we want to ship)
#   Machine:     x86_64-win64 (the actual Windows PC)
#
# Phase 1 -- compiler cycle:
#   ppcrossx64.exe (an i386 cross-compiler) compiles the compiler source
#   and produces ppcx64.exe, a genuine 64-bit Windows executable.
#
# Phase 2 -- RTL, packages, utils:
#   The newly built ppcx64.exe compiles everything else for x86_64-win64.
#
# On Linux and macOS with a native bootstrap this issue does not arise:
# fpmake is the same CPU as the target, IsDifferentFromBuild() returns
# false, and programs are always built.  The notes below are recorded here
# so the whole project history lives in one place (the Windows build,
# build.ps1, is the one that actually needs the flags described).
#
# -------------------------------------------------------------------------
# WHY build.ps1 USES BUILDFULLNATIVE=1 AND NOT UTILS=1
# -------------------------------------------------------------------------
# Two superficially similar make flags control utility-program building:
#
#   UTILS=1           -- tells the top-level Makefile to include utils/ in
#                        the build and install passes.  Necessary but not
#                        sufficient to get the utility .exe files built.
#
#   BUILDFULLNATIVE=1 -- implies UTILS=1 and also suppresses the -scp flag
#                        that every utils sub-Makefile otherwise adds to
#                        fpmake invocations.
#
# The -scp flag means --skipcrossprograms.  On Windows, fpmake.exe is
# itself a 32-bit i386-win32 binary (compiled from the bootstrap).  When
# asked to build programs for x86_64-win64 it calls IsDifferentFromBuild(),
# which returns true because x86_64 != i386.  With -scp active, fpmake
# silently skips every program target -- unit packages compile normally,
# but none of the utility executables are produced.  The build exits 0 with
# no error, so the omission is invisible without checking the staging dir.
#
# Setting BUILDFULLNATIVE=1 removes -scp, telling fpmake to build programs
# unconditionally regardless of IsDifferentFromBuild().
#
# -------------------------------------------------------------------------
# BUILD-STAMP BEHAVIOUR
# -------------------------------------------------------------------------
# The top-level Makefile gates the entire bootstrap sequence behind a stamp
# file (build-stamp.<target>).  Once the stamp exists, 'make all' is a
# no-op -- it prints "Nothing to be done for 'all'" and exits 0 without
# running any build steps, including utils.  The stamp records only that
# *a* build completed, not which flags were active.
#
# These native scripts do not delete the stamps (native rebuilds are
# expected to start clean or use 'make distclean').  build.ps1 deletes them
# before every run so the recipe always executes fresh.
#
# -------------------------------------------------------------------------

# Map uname -m to the FPC arch target and the native compiler binary name.
# Sets: ARCH_TARGET, PPC_BIN
bt_detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)        ARCH_TARGET="x86_64";  PPC_BIN="ppcx64" ;;
    arm64|aarch64) ARCH_TARGET="aarch64"; PPC_BIN="ppca64" ;;
    i386|i686)     ARCH_TARGET="i386";    PPC_BIN="ppc386" ;;
    *) echo "Unsupported architecture: $arch" >&2; return 1 ;;
  esac
}

# Locate the bootstrap fpc compiler.
# Order: $FPC_BOOTSTRAP -> `which fpc` -> $BT_LEGACY_FALLBACK
# Sets: BOOTSTRAP_BIN (the fpc binary), BOOTSTRAP (its prefix dir)
bt_detect_bootstrap() {
  if [ -n "${FPC_BOOTSTRAP:-}" ] && [ -x "$FPC_BOOTSTRAP" ]; then
    BOOTSTRAP_BIN="$FPC_BOOTSTRAP"
    echo "Bootstrap: using \$FPC_BOOTSTRAP"
  elif command -v fpc >/dev/null 2>&1; then
    BOOTSTRAP_BIN="$(command -v fpc)"
    echo "Bootstrap: found via \`which fpc\`"
  elif [ -n "${BT_LEGACY_FALLBACK:-}" ] && [ -x "$BT_LEGACY_FALLBACK" ]; then
    BOOTSTRAP_BIN="$BT_LEGACY_FALLBACK"
    echo "Bootstrap: using legacy fallback ${BT_LEGACY_FALLBACK}"
  else
    echo "Error: No bootstrap FPC compiler found." >&2
    echo "Install FPC 3.2.2, ensure it is on PATH, or set FPC_BOOTSTRAP=/path/to/fpc" >&2
    return 1
  fi

  # Derive the prefix from the binary path (e.g. /usr/local/bin/fpc -> /usr/local)
  BOOTSTRAP="$(cd "$(dirname "$BOOTSTRAP_BIN")/.." && pwd)"

  echo "Bootstrap compiler: ${BOOTSTRAP_BIN} ($(${BOOTSTRAP_BIN} -iV))"
  echo "Source directory:   ${SRCDIR}"
  echo "OS/Arch target:     ${OS_TARGET}/${ARCH_TARGET}"
  echo ""
}

# Lock the PATH down to just the bootstrap compiler plus essential system
# tools.  This is an allowlist: it deliberately omits /usr/local/bin,
# /opt/homebrew/bin, /opt/local/bin, etc. so a previously-installed trunk
# fpc cannot shadow the bootstrap.
bt_lockdown_path() {
  export PATH="${BOOTSTRAP}/bin:/usr/bin:/bin"
  echo "Build PATH: ${PATH}"
  echo "which fpc:  $(command -v fpc || echo '(none)')"
  echo "which as:   $(command -v as  || echo '(none)')"
  echo "which ld:   $(command -v ld  || echo '(none)')"
  echo ""
}

# Run the full build, teeing output to build.log.
bt_run_build() {
  cd "$SRCDIR"
  make all 2>&1 | tee build.log
}

# Print the post-build summary and install hints.
bt_print_summary() {
  local ppc_built newver
  ppc_built="${SRCDIR}/compiler/${PPC_BIN}"

  echo ""
  echo "=== Build complete ==="
  echo "New compiler: ${ppc_built} ($(${ppc_built} -iV))"
  echo "Build log:    ${SRCDIR}/build.log"
  newver="$(${ppc_built} -iV)"

  echo ""
  echo "To install to /usr/local, run:"
  echo ""
  echo "  sudo PATH=${BOOTSTRAP}/bin:/usr/bin:/bin make install INSTALL_PREFIX=/usr/local"
  echo "  sudo ln -sf /usr/local/lib/fpc/${newver}/${PPC_BIN} /usr/local/bin/${PPC_BIN}"
  echo "  sudo mkdir -p /usr/local/lib/fpc/etc"
  echo "  /usr/local/bin/fpcmkcfg -d 'basepath=/usr/local/lib/fpc/\$fpcversion' \\"
  echo "    | sudo tee /usr/local/lib/fpc/etc/fpc.cfg > /dev/null"
}

# Portable file mtime in epoch seconds: macOS `stat -f` vs GNU `stat --format`.
bt_file_mtime() {
  if [ "$(uname -s)" = "Darwin" ]; then
    stat -f '%m' "$1"
  else
    stat --format='%Y' "$1"
  fi
}
