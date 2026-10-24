#!/usr/bin/env bash
# Turn off all RGB: OpenRazer (D-Bus), razer-laptop-control, OpenRGB if installed.
# polychromatic-cli is deprecated, talk to the OpenRazer daemon directly:
# https://docs.polychromatic.app/faqs/#why-is-the-cli-deprecated

echo "==> Turning off OpenRazer devices..."
for serial in $(busctl --user call org.razer /org/razer razer.devices getDevices 2>/dev/null | grep -o '"[^"]*"' | tr -d '"'); do
    path="/org/razer/device/$serial"
    # Every zone exposes set<Zone>None and/or set<Zone>Brightness
    busctl --user introspect org.razer "$path" | awk '/ interface /{i=$1} /^\.set[A-Za-z]*(None|Brightness) /{print i, substr($1, 2)}' |
    while read -r iface method; do
        case "$method" in
            *None) busctl --user call org.razer "$path" "$iface" "$method" ;;
            *Brightness) busctl --user call org.razer "$path" "$iface" "$method" d 0 ;;
        esac
    done
done

if command -v razer-cli &> /dev/null; then
    echo "==> Turning off laptop keyboard and logo..."
    for ac in ac bat; do
        razer-cli write brightness "$ac" 0 > /dev/null || true
        razer-cli write logo "$ac" 0 > /dev/null || true
    done
fi

if command -v openrgb &> /dev/null; then
    echo "==> Turning off OpenRGB devices..."
    openrgb --mode off || openrgb --color 000000 || true
elif flatpak info org.openrgb.OpenRGB &> /dev/null; then
    echo "==> Turning off OpenRGB devices..."
    flatpak run org.openrgb.OpenRGB --mode off || flatpak run org.openrgb.OpenRGB --color 000000 || true
fi

echo "==> RGB off!"
