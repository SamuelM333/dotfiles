#!/usr/bin/env bash
# Run after `just -g claude-rc` exits. Never fail because a peripheral is missing.

razer-cli write power ac 0 || true
razer-cli write fan ac 0 || true

"$(dirname "$0")/rgb-on.sh" || true
