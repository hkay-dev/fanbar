#!/usr/bin/env bash
# Ship it for Fanbar: builds this commit, signs it with Vesper Self-Signed (SIGN_IDENTITY picks another
# certificate, or `-` for ad-hoc), installs it in /Applications (SHIP_APP_DIR picks another folder) and clears
# quarantine. The steps live in armada-ship-lib.sh on PATH.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root=$PWD
lib="$(command -v armada-ship-lib.sh)" || { echo "ship: armada-ship-lib.sh is not on PATH (Armada's bin/ links it into ~/.local/bin)" >&2; exit 1; }
. "$lib"

name="Fanbar"
project="fanbar"
identity="${SIGN_IDENTITY:-Vesper Self-Signed}"
dest_dir="${SHIP_APP_DIR:-/Applications}"
record="$root/build/stable-installed-commit"

ship_check_clean
ship_check_identity
ship_stage

[[ -f Package.swift ]] || ship_fail "no Package.swift to build"
echo "::step Build the app"
ship_build_swift
ship_icon
ship_bundle "$exe" "$bin"

ship_sign
ship_install
ship_record
echo "ship: installed $name ${commit:0:9} at $dest_dir/$name.app"
