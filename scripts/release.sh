#!/bin/sh
# Build a Developer ID signed, notarized, stapled Cyllene.dmg in dist/.
#   ./scripts/release.sh            # archive, sign, dmg, notarize, staple
#   ./scripts/release.sh --no-notarize
set -e
cd "$(dirname "$0")/.."
IDENTITY="Developer ID Application: Joshua Trommel (QMM486NPYC)"
TEAM=QMM486NPYC
VERSION=$(grep MARKETING_VERSION project.yml | awk '{print $2}')
export ASC_BYPASS_KEYCHAIN=1

rm -rf dist && mkdir -p dist
xcodegen generate >/dev/null
xcodebuild archive -scheme Cyllene -configuration Release -archivePath dist/Cyllene.xcarchive \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM=$TEAM OTHER_CODE_SIGN_FLAGS=--timestamp | tail -1

cp -R dist/Cyllene.xcarchive/Products/Applications/Cyllene.app dist/
codesign --verify --deep --strict dist/Cyllene.app
codesign -dv dist/Cyllene.app 2>&1 | grep -E "Authority=Developer ID|flags=.*runtime" >/dev/null || { echo "not Developer ID signed with hardened runtime"; exit 1; }

# drag-to-Applications disk image
mkdir -p dist/dmg && cp -R dist/Cyllene.app dist/dmg/ && ln -s /Applications dist/dmg/Applications
hdiutil create -volname "Cyllene $VERSION" -srcfolder dist/dmg -ov -format UDZO dist/Cyllene.dmg >/dev/null
rm -rf dist/dmg
codesign --sign "$IDENTITY" --timestamp dist/Cyllene.dmg

[ "$1" = "--no-notarize" ] && { echo "dist/Cyllene.dmg (not notarized)"; exit 0; }
asc notarization submit --file dist/Cyllene.dmg --wait --output table
xcrun stapler staple dist/Cyllene.dmg
spctl -a -t open --context context:primary-signature -v dist/Cyllene.dmg
echo "dist/Cyllene.dmg $VERSION ready"
