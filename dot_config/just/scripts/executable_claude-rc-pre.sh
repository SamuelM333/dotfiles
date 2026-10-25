#!/usr/bin/env bash
# Run before `just -g claude-rc`. Never fail because a peripheral is missing.

"$(dirname "$0")/rgb-off.sh" || true

razer-cli write power ac 0 || true
razer-cli write fan ac 0 || true

# Keep the machine awake while sessions are reachable (GNOME Caffeine extension)
dconf write /org/gnome/shell/extensions/caffeine/cli-toggle true || true
