# Power profile
power_integer=`cat $HOME/.config/scopebuddy/scopebuddy-razer-power-integer.txt`
fan_rpm=`cat $HOME/.config/scopebuddy/scopebuddy-razer-fan-rpm.txt`

razer-cli write power ac "$power_integer"
razer-cli write fan ac "$fan_rpm"