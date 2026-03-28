#!/bin/bash
#
# Uninstall the FPC 3.2.2 bootstrap compiler that was installed to /usr
# by the official install.sh script.
#
# Usage: sudo bash uninstall-bootstrap.sh
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: must run as root (sudo bash $0)" >&2
  exit 1
fi

echo "=== Uninstalling FPC 3.2.2 bootstrap from /usr ==="

# --- Binaries in /usr/bin ---
BINS=(
  bin2obj data2inc delp fp fpc fpcjres fpclasschart fpclasschart.rsj
  fpcmake fpcmkcfg fpcmkcfg.rsj fpcres fpcsubst fpcsubst.rsj fppkg
  grab_vcsa h2pas instantfpc json2pas mkarmins mkx86ins
  pas2fpm pas2jni pas2js pas2ut pas2ut.rsj postw32 ppcx64
  ppudump ppufiles ppumove ptop rmcvsdir rstconv unitdiff
)

echo "Removing binaries from /usr/bin ..."
for b in "${BINS[@]}"; do
  f="/usr/bin/$b"
  if [ -f "$f" ]; then
    rm -v "$f"
  fi
done

# --- Library/units tree ---
echo "Removing /usr/lib/fpc ..."
rm -rfv /usr/lib/fpc

# --- Config files ---
echo "Removing config files ..."
rm -fv /etc/fpc.cfg
rm -fv /etc/fppkg.cfg
rm -rfv /etc/fppkg

# --- Documentation and demos ---
echo "Removing documentation ..."
rm -rfv /usr/share/doc/fpc-3.2.2

echo ""
echo "=== Done. FPC 3.2.2 bootstrap removed from /usr. ==="
echo "Verify: running 'which fpc' should return nothing."
