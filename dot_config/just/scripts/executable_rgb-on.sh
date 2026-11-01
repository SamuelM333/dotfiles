#!/usr/bin/env bash
# Turn on all RGB as static green (#00FF00): OpenRazer (D-Bus), razer-laptop-control, OpenRGB if installed.
# polychromatic-cli is deprecated, talk to the OpenRazer daemon directly:
# https://docs.polychromatic.app/faqs/#why-is-the-cli-deprecated
#
# A wireless mouse on its dock (Basilisk V3 Pro 35K on the Mouse Dock Pro) only exposes the
# dock's LEDs. The last state is saved so rgb-watch.sh re-applies it when the mouse is cabled.

R=0 G=255 B=0

echo "==> Turning on OpenRazer devices..."
found=""
for serial in $(busctl --user call org.razer /org/razer razer.devices getDevices 2>/dev/null | grep -o '"[^"]*"' | tr -d '"'); do
    path="/org/razer/device/$serial"
    name=$(busctl --user call org.razer "$path" razer.device.misc getDeviceName | cut -d'"' -f2)
    type=$(busctl --user call org.razer "$path" razer.device.misc getDeviceType | cut -d'"' -f2)
    echo "    $name"
    found+=" $type:$name;"
    # Every zone exposes set<Zone>Static and/or set<Zone>Brightness
    busctl --user introspect org.razer "$path" | awk '/ interface /{i=$1} /^\.set[A-Za-z]*(Static|Brightness) /{print i, substr($1, 2)}' |
    while read -r iface method; do
        case "$method" in
            *Static) busctl --user call org.razer "$path" "$iface" "$method" yyy "$R" "$G" "$B" ;;
            *Brightness) busctl --user call org.razer "$path" "$iface" "$method" d 100 ;;
        esac
    done
done
if [[ "$found" == *Dock* && "$found" != *" mouse:"* ]]; then
    echo "    (mouse is wireless on the dock: rgb-watch re-applies this when it is plugged in)"
fi

if command -v razer-cli &> /dev/null; then
    echo "==> Turning on laptop keyboard and logo..."
    razer-cli standard-effect static "$R" "$G" "$B" > /dev/null || true
    for ac in ac bat; do
        razer-cli write brightness "$ac" 100 > /dev/null || true
        razer-cli write logo "$ac" 1 > /dev/null || true
    done
fi

if command -v openrgb &> /dev/null; then
    echo "==> Turning on OpenRGB devices..."
    openrgb --mode static --color 00FF00 || true
elif flatpak info org.openrgb.OpenRGB &> /dev/null; then
    echo "==> Turning on OpenRGB devices..."
    flatpak run org.openrgb.OpenRGB --mode static --color 00FF00 || true
fi

state="${XDG_STATE_HOME:-$HOME/.local/state}/rgb"
mkdir -p "$state" && echo on > "$state/state"

echo "==> RGB on!"
