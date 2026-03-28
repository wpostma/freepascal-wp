#!/bin/bash
#
# Build FreePascal trunk from source using the bootstrap compiler.
#
# Uses a locked-down PATH so there is zero ambiguity about which
# compiler performs the bootstrap — always /opt/fpc-3.2.2, never
# whatever happens to be in /usr/local/bin.
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
