#!/usr/bin/env bash
# Never fail on exit because a peripheral is missing.

razer-cli write power ac 0 || true
razer-cli write fan ac 0 || true

input-remapper-control --command stop --device "Razer Razer Tartarus V2" || true
