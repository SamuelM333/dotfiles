# Turn off all RGB: OpenRazer (D-Bus), razer-laptop-control, OpenRGB if installed
rgb-off:
    {{ justfile_directory() }}/scripts/rgb-off.sh

# Turn on all RGB as static Razer green: OpenRazer (D-Bus), razer-laptop-control, OpenRGB if installed
rgb-on:
    {{ justfile_directory() }}/scripts/rgb-on.sh

# Performance power mode + fixed fan speed, same as the ScopeBuddy pre-hook
fan-game rpm="5000" ac="ac":
    razer-cli write power {{ ac }} 1
    razer-cli write fan {{ ac }} {{ rpm }}

# Balanced power mode + auto fan, same as the ScopeBuddy post-hook
fan-auto ac="ac":
    razer-cli write power {{ ac }} 0
    razer-cli write fan {{ ac }} 0

# Show current fan setting, actual RPM and power mode
fan-status ac="ac":
    razer-cli read fan {{ ac }}
    razer-cli read fan-rpm
    razer-cli read power {{ ac }}
