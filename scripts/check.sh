#!/usr/bin/env bash
# Fanbar's quick check: a debug swift build with the shared Mac env (Xcode and flags from mac-env.sh). Runs from any
# folder; apps.yml runs it inside `qm with build fanbar`, which sets the job count.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
. mac-env.sh || exit 1
mac_swift_build_flags
exec swift build "${MAC_SWIFT_BUILD_FLAGS[@]}"
