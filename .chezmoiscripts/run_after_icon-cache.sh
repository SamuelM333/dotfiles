#!/bin/bash

# Rebuild the user icon cache when icons were added after it was written.
# GNOME Shell trusts icon-theme.cache and skips icons it doesn't list, so an
# app that drops icons into ~/.local/share/icons without refreshing the cache
# (like the claude-desktop-linux brew cask) shows a generic dock icon.
# find also compares directory times: cask installs keep the icons' old file
# times, but adding them still updates the */apps directories.
# Without a cache, GTK scans the directories itself, so there's nothing to fix.

DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
CACHE="$DIR/icon-theme.cache"

[ -f "$CACHE" ] || exit 0
command -v gtk-update-icon-cache >/dev/null || exit 0

if [ -n "$(find "$DIR" -newer "$CACHE" -print -quit)" ]; then
    gtk-update-icon-cache -f -t -q "$DIR"
fi
