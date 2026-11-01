#!/bin/sh
# Ship a tagged version: notarized DMG, GitHub release, Homebrew cask, landing.
#   scripts/ship.sh 6.0.0 "What changed, one paragraph."
set -e
V="$1"; NOTES="$2"
cd "$(dirname "$0")/.."
./scripts/release.sh | tail -1
xcrun stapler validate dist/Cyllene.dmg >/dev/null
gh release create "v$V" dist/Cyllene.dmg --title "Cyllene $V" --notes "$NOTES" >/dev/null
SHA=$(shasum -a 256 dist/Cyllene.dmg | awk '{print $1}')
# The cask must match what GitHub serves, not just the local file.
[ "$(curl -sL "https://github.com/nulljosh/cyllene/releases/download/v$V/Cyllene.dmg" | shasum -a 256 | awk '{print $1}')" = "$SHA" ]
TAP=../homebrew-tap
sed -i '' -E "s/version \"[^\"]+\"/version \"$V\"/; s/sha256 \"[0-9a-f]+\"/sha256 \"$SHA\"/" "$TAP/Casks/hermes.rb"
git -C "$TAP" commit -qm "hermes $V" Casks/hermes.rb && git -C "$TAP" push -q
./deploy.sh | tail -1
echo "SHIPPED $V"
