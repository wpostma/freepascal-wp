#!/bin/bash
#
# Build FreePascal trunk from source on Linux using the bootstrap compiler.
#
# Normally invoked via ./build.sh (which dispatches by OS), but can be run
# directly.  Shared logic and the cross-compile/build-stamp documentation
# live in _build-tool.sh.
#
# Bootstrap compiler detection order:
#   1. FPC_BOOTSTRAP env var   — path to the fpc binary
#   2. `which fpc`             — whatever is on your current PATH
#   3. /opt/fpc-3.2.2/bin/fpc  — legacy fallback (see install-bootstrap.sh)
#
set -euo pipefail

SRCDIR="$(cd "$(dirname "$0")" && pwd)"
source "${SRCDIR}/_build-tool.sh"

OS_TARGET="linux"
BT_LEGACY_FALLBACK="/opt/fpc-3.2.2/bin/fpc"

bt_detect_arch
bt_detect_bootstrap
bt_lockdown_path
bt_run_build
bt_print_summary
