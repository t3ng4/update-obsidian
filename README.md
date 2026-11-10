# obsidian update script with latest obsidian github appimage rls + checksum check

# AppImage from https://github.com/obsidianmd/obsidian-releases/releases
# obsidian installation paths
APP_DIR="/path/to/obsidian/folder/" # where AppImage is placed
DESKTOP_FILE="$HOME/.local/share/applications/obsidian.desktop" # path to obsidian desktop link. adjust if needed
ICON="$HOME/.local/share/icons/Obsidian/obsidian-custom.png" # path to custom image for obsidian icon

chmod +x update-obsidian.sh
./update-obsidian.sh
