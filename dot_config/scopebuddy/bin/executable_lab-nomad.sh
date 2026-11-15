#!/bin/sh
# Drains this machine's lab Nomad node while a game runs, so jobs on the GPU (ollama)
# move off, and takes jobs again when the game exits. Called by pre-hook.sh (drain) and
# post-hook.sh (enable). The same as `just clients disable` / `enable` in the lab repo
# (clients/AGENTS.md): this machine's agent, with the workstation-drain token.
# Does nothing when Nomad or the token isn't set up, and never fails the game.
# A node that was already disabled is left alone: only a drain started here is undone.

nomad=/usr/local/bin/nomad
token="${XDG_CONFIG_HOME:-$HOME/.config}/lab/nomad-drain.token"
marker="${XDG_RUNTIME_DIR:-/tmp}/lab-nomad-game-drain"

[ -x "$nomad" ] && [ -r "$token" ] || exit 0

local_nomad() {
  NOMAD_ADDR=http://127.0.0.1:4646 NOMAD_TOKEN="$(cat "$token")" timeout 10 "$nomad" "$@"
}

case "$1" in
  drain)
    # Another game already drained it
    [ -e "$marker" ] && exit 0
    [ "$(local_nomad node status -self -t '{{.SchedulingEligibility}}' 2>/dev/null)" = eligible ] || exit 0
    # -detach: the game starts now; jobs get the usual 30 s to stop
    local_nomad node drain -self -enable -yes -detach -deadline 30s >/dev/null 2>&1 \
      && touch "$marker"
    ;;
  enable)
    [ -e "$marker" ] || exit 0
    local_nomad node drain -self -disable -yes >/dev/null 2>&1
    local_nomad node eligibility -self -enable >/dev/null 2>&1 && rm -f "$marker"
    ;;
esac
exit 0
