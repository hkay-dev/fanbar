#!/usr/bin/env bash
# Ship it for Fanbar (written by deckhand app new): builds this commit, signs it with Vesper Self-Signed
# (SIGN_IDENTITY picks another certificate, or `-` for ad-hoc), installs it in /Applications (SHIP_APP_DIR picks
# another folder), clears quarantine and records the commit.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root=$PWD

name="Fanbar"
project="fanbar"
identity="${SIGN_IDENTITY:-Vesper Self-Signed}"
dest_dir="${SHIP_APP_DIR:-/Applications}"
destination="$dest_dir/$name.app"
record="$root/build/stable-installed-commit"

fail() { echo "ship: $*" >&2; exit 1; }

echo "::step Check the repo"
echo "ship: checking the repo is clean"
dirty="$(git status --porcelain --untracked-files=no)"
[[ -z "$dirty" ]] || fail "uncommitted changes; commit them first, only committed code ships"
commit="$(git rev-parse HEAD)"

echo "::step Check the signing identity"
echo "ship: checking the $identity signing identity"
[[ "$identity" == - ]] || security find-identity -v -p codesigning | grep -Fq "\"$identity\"" ||
    fail "the $identity signing identity is missing from the login keychain"

mkdir -p build
stage="$(mktemp -d "$root/build/ship-stage.XXXXXX")"
trap 'rm -rf "${stage:?}"' EXIT
app="$stage/$name.app"

xcodeproj="$(find . -maxdepth 2 -name '*.xcodeproj' -not -path './build/*' -not -path './.build/*' | head -n 1)"
if [[ -n "$xcodeproj" ]]; then
    echo "::step Build the app"
    echo "ship: building $name with xcodebuild"
    scheme="$(xcodebuild -list -json -project "$xcodeproj" | jq -r '.project.schemes[0]')"
    [[ -n "$scheme" && "$scheme" != null ]] || fail "$xcodeproj has no scheme to build"
    derived="$root/build/DerivedData"
    xcodebuild -project "$xcodeproj" -scheme "$scheme" -configuration Release -destination 'platform=macOS,arch=arm64' \
        -derivedDataPath "$derived" -skipPackagePluginValidation -skipMacroValidation build >"$stage/build.log" 2>&1 ||
        { tail -n 20 "$stage/build.log" >&2; fail "xcodebuild failed"; }
    built="$(find "$derived/Build/Products/Release" -maxdepth 1 -name '*.app' | head -n 1)"
    [[ -n "$built" ]] || fail "xcodebuild made no .app in $derived/Build/Products/Release"
    ditto "$built" "$app"
else
    [[ -f Package.swift ]] || fail "no .xcodeproj or Package.swift to build"
    echo "::step Build the app"
    echo "ship: building $name with swift build"
    exe="$(swift package dump-package | jq -r '[.products[] | select(.type | has("executable"))][0].name')"
    [[ -n "$exe" && "$exe" != null ]] || fail "Package.swift has no executable product"
    swift build -c release >"$stage/build.log" 2>&1 || { tail -n 20 "$stage/build.log" >&2; fail "swift build failed"; }
    bin="$(swift build -c release --show-bin-path)/$exe"
    [[ -x "$bin" ]] || fail "swift build made no $exe"
    echo "ship: making the app bundle"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$bin" "$app/Contents/MacOS/$exe"
    xcrun actool AppIcon.icon --compile "$app/Contents/Resources" --app-icon AppIcon --platform macosx \
        --minimum-deployment-target 14.0 --output-partial-info-plist "$stage/icon.plist" >"$stage/actool.log" 2>&1 ||
        { tail -n 20 "$stage/actool.log" >&2; fail "actool failed to compile AppIcon.icon"; }
    cat >"$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>$exe</string>
    <key>CFBundleIdentifier</key><string>dev.hkay.$project</string>
    <key>CFBundleName</key><string>$name</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIconName</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>${commit:0:9}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
PLIST
fi

echo "::step Sign the app"
echo "ship: signing with $identity"
codesign --force --deep -s "$identity" "$app"
codesign --verify --deep --strict "$app"

echo "::step Install the app"
echo "ship: installing at $destination"
mkdir -p "$dest_dir"
rm -rf "${destination:?}"
mv "$app" "$destination"

echo "ship: clearing quarantine"
xattr -dr com.apple.quarantine "$destination" 2>/dev/null || true

echo "::step Record the install"
printf '%s\n' "$commit" >"$record"
echo "ship: installed $name ${commit:0:9} at $destination"
