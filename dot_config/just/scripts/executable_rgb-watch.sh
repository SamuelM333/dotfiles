#!/usr/bin/env bash
# Re-apply the last rgb-on/rgb-off whenever the OpenRazer daemon picks up a device, e.g. the
# Basilisk V3 Pro 35K plugged in by cable. Run by ~/.config/systemd/user/rgb-watch.service.

dir=$(dirname "$(readlink -f "$0")")
state="${XDG_STATE_HOME:-$HOME/.local/state}/rgb/state"

busctl --user monitor --match "type='signal',interface='razer.devices',member='device_added'" |
while read -r line; do
    [[ "$line" == *Member=device_added* ]] || continue
    sleep 2 # let the daemon finish setting up the device
    case "$(cat "$state" 2>/dev/null)" in
        on) "$dir/rgb-on.sh" ;;
        off) "$dir/rgb-off.sh" ;;
    esac
done
