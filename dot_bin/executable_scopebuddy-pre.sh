#!/usr/bin/env bash

power_output=$(razer-cli read power ac)
fan_output=$(razer-cli read fan ac)

power_string=$(echo "$power_output" | grep -oP 'Current power setting: \K.*')
power_integer=$(echo "$power_output" | grep -oP 'pwr: \K\d+')
fan_rpm=$(echo "$fan_output" | grep -oP 'rpm: \K\d+')

echo $power_integer > $HOME/.config/scopebuddy/scopebuddy-razer-power-integer.txt
echo $fan_rpm > $HOME/.config/scopebuddy/scopebuddy-razer-fan-rpm.txt

if [[ (-z "$power_string" && -z "$power_integer") || -z "$fan_rpm" ]]; then
    echo "Error: Could not extract current power or fan settings from razer-cli."
    exit 1
fi

razer-cli write power ac 1
razer-cli write fan ac 5000