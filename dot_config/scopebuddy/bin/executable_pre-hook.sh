#!/usr/bin/env bash

razer-cli write power ac 1
razer-cli write fan ac 5000

input-remapper-control --command start --device "Razer Razer Tartarus V2" --preset "General"
