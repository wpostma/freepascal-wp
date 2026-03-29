#!/bin/bash
#
# Rebuild and reinstall FPC fcl-net package (ssockets, fphttpserver, etc.)
# after modifying sources in packages/fcl-net/src/.
#
# Copies the rebuilt .ppu/.o files into the installed FPC unit directory
# so Lazarus/LCL picks them up on next build.
#
set -euo pipefail

SRCDIR="$(cd "$(dirname "$0")" && pwd)"
FPCVER="$(fpc -iV)"
INSTALLED="/usr/local/lib/fpc/${FPCVER}/units/x86_64-linux/fcl-net"
BUILT="${SRCDIR}/packages/fcl-net/units/x86_64-linux"

echo "FPC version:  ${FPCVER}"
echo "Source:       ${SRCDIR}/packages/fcl-net/src/"
echo "Build output: ${BUILT}"
echo "Install to:   ${INSTALLED}"
echo ""

# ---- Build ----
echo "Building fcl-net..."
make -C "${SRCDIR}/packages/fcl-net" clean all > /tmp/fcl-net-build.log 2>&1
STATUS=$?

if [ $STATUS -ne 0 ]; then
  echo "FAILED — build errors:"
  grep -i "error\|fatal" /tmp/fcl-net-build.log | head -10
  echo ""
  echo "Full log: /tmp/fcl-net-build.log"
  exit 1
fi

# ---- Verify the build produced files ----
if [ ! -f "${BUILT}/ssockets.ppu" ]; then
  echo "FAILED — ${BUILT}/ssockets.ppu not found after build"
  exit 1
fi

echo "Build OK. Rebuilt units:"
ls -la "${BUILT}"/*.ppu | head -20
echo ""

# ---- Install ----
echo "Installing to ${INSTALLED} (requires sudo)..."
sudo cp -v "${BUILT}"/*.ppu "${BUILT}"/*.o "${BUILT}"/*.rsj "${INSTALLED}/" 2>/dev/null

# ---- Verify ----
echo ""
echo "Verifying installed ssockets.ppu is newer than source..."
SRC_TIME=$(stat --format='%Y' "${SRCDIR}/packages/fcl-net/src/ssockets.pp")
PPU_TIME=$(stat --format='%Y' "${INSTALLED}/ssockets.ppu")

if [ "$PPU_TIME" -ge "$SRC_TIME" ]; then
  echo "OK — installed .ppu is up to date"
else
  echo "WARNING — installed .ppu is older than source, something went wrong"
  exit 1
fi

echo ""
echo "Done. Rebuild your LCL now (e.g. DIAG=1 bash build.sh)"
