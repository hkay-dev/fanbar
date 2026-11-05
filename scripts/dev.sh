#!/usr/bin/env bash
# Fanbar Dev: builds the debug binary under `qm with build fanbar`, bundles it as build/Dev/Fanbar Dev.app (its own
# bundle id, so it never replaces the installed Fanbar), signs it with Vesper Self-Signed and opens it in the
# background with `open -g -j -n` (docs/mac-dev-builds.md). `scripts/dev.sh build` only builds the bundle.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root=$PWD
lib="$(command -v armada-ship-lib.sh)" || { echo "dev: armada-ship-lib.sh is not on PATH (Armada's bin/ links it into ~/.local/bin)" >&2; exit 1; }
. "$lib"

name="Fanbar Dev"
project="fanbar-dev"
identity="${SIGN_IDENTITY:-Vesper Self-Signed}"
commit="$(git rev-parse HEAD)"

qm with build fanbar -- bash -c '. mac-env.sh || exit 1; mac_swift_build_flags; exec swift build "${MAC_SWIFT_BUILD_FLAGS[@]}"' ||
    ship_fail "swift build failed, its output is above"
bin="$root/.build/debug/Fanbar"
[[ -x "$bin" ]] || ship_fail "swift build made no Fanbar binary"

ship_stage
ship_icon
ship_bundle Fanbar "$bin"
ship_sign
dest="$root/build/Dev/$name.app"
mkdir -p "${dest%/*}"
rm -rf "$dest"
mv "$app" "$dest"
echo "dev: built $dest"

[[ "${1:-}" == build ]] && exit 0
open -g -j -n "$dest"
