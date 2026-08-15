#!/bin/bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cinderbox-pack.zip>" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_ARCHIVE="$(realpath "$1")"
DESTINATION_ARCHIVE="$REPOSITORY_ROOT/cinderbox-pack.zip"
STATE_FILE="$REPOSITORY_ROOT/release.env"

if [ ! -f "$SOURCE_ARCHIVE" ]; then
    echo "ERROR: Pack archive not found: $SOURCE_ARCHIVE" >&2
    exit 1
fi

unzip -tqq "$SOURCE_ARCHIVE"
while IFS= read -r entry; do
    if [[ "$entry" == /* ]] || [[ "$entry" == *\\* ]] || [[ "/$entry/" == *"/../"* ]]; then
        echo "ERROR: Unsafe pack archive entry: $entry" >&2
        exit 1
    fi
    case "$entry" in
        Mods/*) ;;
        *)
            echo "ERROR: Unexpected pack archive entry: $entry" >&2
            exit 1
            ;;
    esac
done < <(unzip -Z1 "$SOURCE_ARCHIVE" | sed '/\/$/d')

required_entries=(
    "Mods/CinderTap/CinderTap.dll"
    "Mods/CinderTap/manifest.json"
    "Mods/LetMeRemap/LetMeRemap.dll"
    "Mods/LetMeRemap/manifest.json"
    "Mods/UIInfoSuite2Redux/UIInfoSuite2Redux.dll"
    "Mods/UIInfoSuite2Redux/manifest.json"
    "Mods/SoManyMods/SoManyElements/SoManyElements.dll"
    "Mods/SoManyMods/SoManyElements/manifest.json"
    "Mods/SoManyMods/SoManyToolbars/SoManyToolbars.dll"
    "Mods/SoManyMods/SoManyToolbars/manifest.json"
    "Mods/SoManyMods/SoManyButtons/SoManyButtons.dll"
    "Mods/SoManyMods/SoManyButtons/manifest.json"
)
for required_entry in "${required_entries[@]}"; do
    if ! unzip -Z1 "$SOURCE_ARCHIVE" | grep -Fx "$required_entry" >/dev/null; then
        echo "ERROR: Required pack entry is missing: $required_entry" >&2
        exit 1
    fi
done

state_value() {
    sed -n "s/^$1=//p" "$STATE_FILE"
}

PACK_VERSION="$(state_value PACK_VERSION)"
PREVIOUS_SHA256="$(state_value PACK_SHA256)"
CURRENT_SHA256="$(sha256sum "$SOURCE_ARCHIVE" | awk '{print $1}')"

if ! [[ "$PACK_VERSION" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid pack version: $PACK_VERSION" >&2
    exit 1
fi
if [ -n "$PREVIOUS_SHA256" ] && ! [[ "$PREVIOUS_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "ERROR: Invalid previous pack SHA-256." >&2
    exit 1
fi

if [ "$CURRENT_SHA256" != "$PREVIOUS_SHA256" ]; then
    PACK_VERSION=$((PACK_VERSION + 1))
fi

TEMP_ARCHIVE="$DESTINATION_ARCHIVE.tmp"
TEMP_STATE="$STATE_FILE.tmp"
trap 'rm -f "$TEMP_ARCHIVE" "$TEMP_STATE"' EXIT
cp "$SOURCE_ARCHIVE" "$TEMP_ARCHIVE"
mv "$TEMP_ARCHIVE" "$DESTINATION_ARCHIVE"

cat > "$TEMP_STATE" <<EOF
PACK_VERSION=$PACK_VERSION
PACK_SHA256=$CURRENT_SHA256
EOF
mv "$TEMP_STATE" "$STATE_FILE"

echo "Cinderbox pack imported as pack-v$PACK_VERSION."
echo "Pack SHA-256: $CURRENT_SHA256"
