#!/usr/bin/env bash
# Run before `just -g claude-rc`. Never fail because a peripheral is missing.

"$(dirname "$0")/rgb-off.sh" || true

razer-cli write power ac 1 || true
razer-cli write fan ac 5000 || true
