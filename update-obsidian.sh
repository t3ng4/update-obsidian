# obsidian update script with latest obsidian github appimage rls + checksum check

#!/usr/bin/env bash
set -Eeuo pipefail

# obsidian installation paths
APP_DIR="/path/to/obsidian/folder/"
DESKTOP_FILE="$HOME/.local/share/applications/obsidian.desktop" # path to obsidian desktop link. adjust if needed
ICON="$HOME/.local/share/icons/Obsidian/obsidian-custom.png" # path to custom image for obsidian icon

# Required tools
for cmd in curl jq sha256sum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing dependency: $cmd"
        echo "Install it with: sudo pacman -S curl jq"
        exit 1
    fi
done

# Check that the installation drive is mounted
if [[ ! -d "$APP_DIR" ]]; then
    echo "Error: Obsidian drive is not mounted: $APP_DIR"
    exit 1
fi

if [[ ! -f "$DESKTOP_FILE" ]]; then
    echo "Error: Obsidian desktop launcher not found."
    exit 1
fi

echo "Checking for Obsidian updates..."

# get latest official gitHub release
RELEASE=$(curl -fsSL \
    https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)

VERSION=$(jq -r '.tag_name | ltrimstr("v")' <<< "$RELEASE")

# find the standard x86_64 AppImage, not the ARM version
ASSET=$(jq -c '
    .assets[]
    | select(.name | test("^Obsidian-[0-9].*\\.AppImage$"))
    | select(.name | contains("arm64") | not)
' <<< "$RELEASE" | head -n 1)

if [[ -z "$ASSET" ]]; then
    echo "Error: Could not find the x86_64 AppImage."
    exit 1
fi

URL=$(jq -r '.browser_download_url' <<< "$ASSET")
DIGEST=$(jq -r '.digest // empty' <<< "$ASSET")

NEW_APP="$APP_DIR/Obsidian-$VERSION.AppImage"
TEMP_APP="$APP_DIR/.obsidian-update-$VERSION.tmp"

# check installed version
if [[ -x "$NEW_APP" ]]; then
    echo "Obsidian $VERSION is already installed."
    exit 0
fi

echo "New version available: $VERSION"
echo "Downloading..."

trap 'rm -f "$TEMP_APP"' EXIT

curl -fL --progress-bar "$URL" -o "$TEMP_APP"

# verify download when GitHub provides a SHA-256 digest
if [[ "$DIGEST" == sha256:* ]]; then
    EXPECTED="${DIGEST#sha256:}"
    ACTUAL=$(sha256sum "$TEMP_APP" | awk '{print $1}')

    if [[ "$EXPECTED" != "$ACTUAL" ]]; then
        echo "Error: SHA-256 verification failed!"
        exit 1
    fi
    echo "SHA-256 verification passed."
else
    echo "Warning: No SHA-256 digest supplied by GitHub."
fi

chmod +x "$TEMP_APP"

# install new version
mv "$TEMP_APP" "$NEW_APP"

# update only the Exec line; preserve custom icon and other settings
sed "s|^Exec=.*|Exec=\"$NEW_APP\" %U|" \
    "$DESKTOP_FILE" > "$DESKTOP_FILE.tmp"

mv "$DESKTOP_FILE.tmp" "$DESKTOP_FILE"

# refresh KDE application menu
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo ""
echo "Obsidian successfully updated to $VERSION!"
echo "AppImage: $NEW_APP"
echo "Custom icon preserved: $ICON"
echo ""
echo "Your old AppImage has been kept as a backup."
