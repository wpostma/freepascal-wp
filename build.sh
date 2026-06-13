#!/bin/bash
#
# Build FreePascal trunk from source.
#
# This is a thin dispatcher: it detects the OS and hands off to the
# matching per-platform script.  The real work and the shared
# documentation (cross-compile situation, BUILDFULLNATIVE, build-stamp
# behaviour) live in _build-tool.sh.  Windows has its own build.ps1.
#
#   macOS  -> build-mac.sh
#   Linux  -> build-linux.sh
#   Windows-> build.ps1 (PowerShell; run that instead of this script)
#
# See how-to-build-instructions.md for details.
#
set -euo pipefail

SRCDIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) exec "${SRCDIR}/build-mac.sh"   "$@" ;;
  Linux)  exec "${SRCDIR}/build-linux.sh" "$@" ;;
  *)
    echo "Unsupported OS: $(uname -s)." >&2
    echo "On Windows, run build.ps1 (PowerShell) instead." >&2
    exit 1
    ;;
esac
