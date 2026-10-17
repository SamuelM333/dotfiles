#!/usr/bin/env bash
# Never fail the game launch because a peripheral is missing.

razer-cli write power ac 1 || true
razer-cli write fan ac 5000 || true

input-remapper-control --command start --device "Razer Razer Tartarus V2" --preset "General" || true

exit 0
