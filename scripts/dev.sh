#!/usr/bin/env bash
# Fanbar Dev: quits the earlier Fanbar Dev by pid (never the installed Fanbar), builds the debug binary under
# `qm with build fanbar`, bundles it as build/Dev/Fanbar Dev.app with the bundle id `<stable id>.dev`, signs it with
# Vesper Self-Signed and opens it in the background with `open -g -j -n` (docs/mac-dev-builds.md).
# `scripts/dev.sh build` only builds the bundle. Dev reads sensors and shows the UI but makes no SMC or energy-mode
# write unless FANBAR_DEV_WRITES=1 is set (`FANBAR_DEV_WRITES=1 scripts/dev.sh` passes it on) or the app gets `--allow-writes`.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root=$PWD
lib="$(command -v armada-ship-lib.sh)" || { echo "dev: armada-ship-lib.sh is not on PATH (Armada's bin/ links it into ~/.local/bin)" >&2; exit 1; }
. "$lib"

name="Fanbar Dev"
project="fanbar"
stable_id="dev.hkay.fanbar"
identity="${SIGN_IDENTITY:-Vesper Self-Signed}"
commit="$(git rev-parse HEAD)"

ship_check_identity

# Only "Fanbar Dev.app" copies: the installed Fanbar runs from /Applications/Fanbar.app and never matches.
if [[ "${1:-}" != build ]]; then
    pids="$(pgrep -f '/Fanbar Dev\.app/Contents/MacOS/' || true)"
    if [[ -n "$pids" ]]; then
        echo "dev: quitting the earlier $name (pid $(echo $pids))"
        kill $pids 2>/dev/null || true
        for _ in {1..50}; do
            pgrep -f '/Fanbar Dev\.app/Contents/MacOS/' >/dev/null || break
            sleep 0.1
        done
    fi
fi

qm with build fanbar -- bash -c '. mac-env.sh || exit 1; mac_swift_build_flags; exec swift build "${MAC_SWIFT_BUILD_FLAGS[@]}"' ||
    ship_fail "swift build failed, its output is above"
bin="$root/.build/debug/Fanbar"
[[ -x "$bin" ]] || ship_fail "swift build made no Fanbar binary"

ship_stage
ship_icon
ship_bundle Fanbar "$bin"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $stable_id.dev" "$app/Contents/Info.plist"
ship_sign
dest="$root/build/Dev/$name.app"
mkdir -p "${dest%/*}"
rm -rf "$dest"
mv "$app" "$dest"
echo "dev: built $dest"

[[ "${1:-}" == build ]] && exit 0
if [[ "${FANBAR_DEV_WRITES:-}" == 1 ]]; then
    open -g -j -n --env FANBAR_DEV_WRITES=1 "$dest"
else
    open -g -j -n "$dest"
fi
