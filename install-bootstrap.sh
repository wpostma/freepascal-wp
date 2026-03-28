#!/bin/bash
#
# Download and install the FPC 3.2.2 bootstrap compiler to /opt/fpc-3.2.2.
# Idempotent — safe to re-run.
#
set -euo pipefail

VERSION=3.2.2
PREFIX=/opt/fpc-${VERSION}
TARBALL="fpc-${VERSION}.x86_64-linux.tar"
URL="https://sourceforge.net/projects/freepascal/files/Linux/${VERSION}/${TARBALL}/download"
WORKDIR=$(mktemp -d)

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

if [ -x "${PREFIX}/bin/fpc" ]; then
  echo "Bootstrap FPC ${VERSION} already installed at ${PREFIX}/bin/fpc"
  "${PREFIX}/bin/fpc" -iV
  exit 0
fi

echo "=== Downloading FPC ${VERSION} bootstrap ==="
wget -q --show-progress "$URL" -O "${WORKDIR}/${TARBALL}"

echo "=== Extracting ==="
cd "$WORKDIR"
tar xf "$TARBALL"

echo "=== Installing to ${PREFIX} ==="
sudo mkdir -p "$PREFIX"
cd "fpc-${VERSION}.x86_64-linux"
printf '%s\n\nY\nY\n' "$PREFIX" | sudo bash install.sh

# --- Generate prefix-specific fpc.cfg ---
# The upstream install.sh writes to /etc/fpc.cfg, which causes
# cross-contamination with other FPC installs. Move the config
# into the bootstrap prefix so it's self-contained.
echo "=== Setting up prefix-specific config ==="
sudo mkdir -p "${PREFIX}/lib/fpc/etc"
"${PREFIX}/bin/fpcmkcfg" \
  -d "basepath=${PREFIX}/lib/fpc/\$fpcversion" \
  | sudo tee "${PREFIX}/lib/fpc/etc/fpc.cfg" > /dev/null

# Clean up /etc files written by install.sh
sudo rm -f /etc/fpc.cfg
sudo rm -f /etc/fppkg.cfg
sudo rm -rf /etc/fppkg

echo ""
echo "=== Installed. Verify: ==="
"${PREFIX}/bin/fpc" -iV
echo "Config: ${PREFIX}/lib/fpc/etc/fpc.cfg"
echo "Location: ${PREFIX}/bin/fpc"
