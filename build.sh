#!/bin/bash
#
# Build FreePascal trunk from source using the bootstrap compiler.
#
# Uses a locked-down PATH so there is zero ambiguity about which
# compiler performs the bootstrap -- always /opt/fpc-3.2.2, never
# whatever happens to be in /usr/local/bin.
#
# -------------------------------------------------------------------------
# CROSS-COMPILATION SITUATION (Win32 bootstrap -> Win64 output)
# -------------------------------------------------------------------------
# The primary build target for this project is x86_64-win64: a full set of
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
# -------------------------------------------------------------------------
# WHY build.ps1 USES BUILDFULLNATIVE=1 AND NOT UTILS=1
# -------------------------------------------------------------------------
# (This script targets Linux and is not affected, but the explanation is
# recorded here so the whole project history is in one place.)
#
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
# On Linux with a native x86_64 bootstrap this issue does not arise:
# fpmake itself is x86_64, the target is x86_64, IsDifferentFromBuild()
# returns false, and programs are always built even without BUILDFULLNATIVE.
# But BUILDFULLNATIVE=1 is harmless on Linux and worth passing anyway for
# consistency.
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
# build.ps1 deletes the stamps before every run so the recipe always
# executes fresh and the stamp is recreated with the correct flags in
# effect.  This script does not delete them (Linux rebuilds are expected
# to start clean or use 'make distclean'), but the same caveat applies.
#
set -euo pipefail

BOOTSTRAP=/opt/fpc-3.2.2
SRCDIR="$(cd "$(dirname "$0")" && pwd)"

# ---- Preflight checks ----

if [ ! -x "${BOOTSTRAP}/bin/fpc" ]; then
  echo "Error: Bootstrap compiler not found at ${BOOTSTRAP}/bin/fpc" >&2
  echo "Run: bash install-bootstrap.sh" >&2
  exit 1
fi

echo "Bootstrap compiler: ${BOOTSTRAP}/bin/fpc ($(${BOOTSTRAP}/bin/fpc -iV))"
echo "Source directory:    ${SRCDIR}"
echo ""

# ---- Locked-down PATH ----
# Only the bootstrap compiler, system binutils/gcc, and coreutils.
# Explicitly excludes /usr/local/bin to prevent picking up a
# previously-installed trunk compiler.

export PATH="${BOOTSTRAP}/bin:/usr/bin:/bin"

echo "Build PATH: ${PATH}"
echo "which fpc:  $(which fpc)"
echo "which as:   $(which as)"
echo "which ld:   $(which ld)"
echo ""

# ---- Build ----

cd "$SRCDIR"
make all 2>&1 | tee build.log

echo ""
echo "=== Build complete ==="
echo "New compiler: ${SRCDIR}/compiler/ppcx64 ($(${SRCDIR}/compiler/ppcx64 -iV))"
echo "Build log:    ${SRCDIR}/build.log"
NEWVER="$(${SRCDIR}/compiler/ppcx64 -iV)"

echo ""
echo "To install to /usr/local, run:"
echo ""
echo "  sudo PATH=${BOOTSTRAP}/bin:/usr/bin:/bin make install INSTALL_PREFIX=/usr/local"
echo "  sudo ln -sf /usr/local/lib/fpc/${NEWVER}/ppcx64 /usr/local/bin/ppcx64"
echo "  sudo mkdir -p /usr/local/lib/fpc/etc"
echo "  /usr/local/bin/fpcmkcfg -d 'basepath=/usr/local/lib/fpc/\$fpcversion' \\"
echo "    | sudo tee /usr/local/lib/fpc/etc/fpc.cfg > /dev/null"
