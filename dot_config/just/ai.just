# AI agents in tmux. `ai` (zsh alias) runs `just -g ai`; see ~/.config/tmux/tmux.conf.

# Agent the launcher starts: Claude Code on the Linux hosts, Cursor's CLI on macOS.
ai_agent := env("AI_AGENT", if os() == "macos" { "agent" } else { "claude" })

# Open (or switch to) a tmux window TITLE (default: current dir name) with the agent in the current dir; COLOR colors its tab, -v/--vim (or AI_VIM=1) adds nvim beside it
[no-cd]
[positional-arguments]
ai *args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir=$PWD
    # Neovim beside the agent is off by default: -v/--vim or a truthy AI_VIM turns it on.
    case ${AI_VIM:-} in
      1 | y | Y | yes | true) vim=1 ;;
      *) vim=0 ;;
    esac
    positional=()
    for arg in "$@"; do
      case $arg in
        -v | --vim) vim=1 ;;
        *) positional+=("$arg") ;;
      esac
    done
    set -- "${positional[@]}"
    title=${1:-}
    # The prefix + a prompt sets AI_NEW_WINDOW: a blank title there always opens a
    # new window named after the dir, even if one with that name exists.
    new_window=0
    if [[ -z $title ]]; then
      title=$(basename -- "$dir")
      [[ -z ${AI_NEW_WINDOW:-} ]] || new_window=1
    fi
    color=${2:-}
    agent={{ quote(ai_agent) }}

    # Windows live in the current session, or in the "ai" session outside tmux.
    if [[ -n ${TMUX:-} ]]; then
      session=$(tmux display-message -p '#{session_name}')
    else
      session=${AI_SESSION:-ai}
    fi

    # Start the server before looking for windows. Loading tmux.conf runs
    # continuum's auto-restore, and start-server returns only after it ends, so
    # a restored session and its windows count as existing below instead of
    # colliding with a new one. A no-op when the server is already running.
    tmux start-server

    # Existing window with this title, matched on @ai_title so a manual rename
    # doesn't create a duplicate. tmux turns tabs into "_" in -F output, so
    # split on the first space (window ids never contain one, titles may).
    win=""
    if ((!new_window)) && tmux has-session -t "=$session" 2>/dev/null; then
      win=$(tmux list-windows -t "=$session" -F '#{window_id} #{@ai_title}' |
        awk -v t="$title" '{ id = $1; sub(/^[^ ]+ /, ""); if ($0 == t) { print id; exit } }')
    fi

    if [[ -z $win ]]; then
      if tmux has-session -t "=$session" 2>/dev/null; then
        win=$(tmux new-window -d -t "=$session:" -n "$title" -c "$dir" -P -F '#{window_id}')
      else
        win=$(tmux new-session -d -s "$session" -n "$title" -c "$dir" -P -F '#{window_id}')
      fi
      tmux set-option -w -t "$win" @ai_title "$title"
      first_pane=$(tmux display-message -p -t "$win" '#{pane_id}')
      # Start each through the shell, so quitting nvim or the agent leaves a prompt.
      if ((vim)); then
        agent_pane=$(tmux split-window -h -d -l 45% -t "$first_pane" -c "$dir" -P -F '#{pane_id}')
        tmux send-keys -t "$first_pane" "nvim ." Enter
        tmux send-keys -t "$agent_pane" "$agent" Enter
        tmux select-pane -t "$first_pane"
      else
        tmux send-keys -t "$first_pane" "$agent" Enter
      fi
    fi

    if [[ -n $color ]]; then
      tmux set-option -w -t "$win" @color "$color"
    fi

    if [[ -n ${TMUX:-} ]]; then
      tmux switch-client -t "$win"
    elif [[ -t 1 ]]; then
      tmux select-window -t "$win"
      exec tmux attach-session -t "=$session"
    else
      echo "ai: $session:$title is ready, attach with: tmux attach -t $session" >&2
    fi

# Mark the tmux window this agent runs in as working, waiting or done (or clear it), or record its session id on the pane (started/ended, AGENT: claude or agent); called from agent hooks
[no-cd]
[positional-arguments]
agent-state state agent="claude":
    #!/usr/bin/env bash
    # Never fails, so a hook can't block the agent.
    state=$1
    agent=${2:-claude}

    # Hooks get JSON on stdin; read it all so the agent isn't left writing to a pipe.
    input=
    [[ -t 0 ]] || input=$(cat)
    command -v tmux >/dev/null 2>&1 || exit 0

    pane=${TMUX_PANE:-}
    if [[ -z $pane ]]; then
      # Environment not inherited: find the pane whose shell is one of our ancestors.
      panes=$(tmux list-panes -a -F '#{pane_pid} #{pane_id}' 2>/dev/null) || exit 0
      pid=$$
      while [[ -n $pid && $pid -gt 1 ]]; do
        pane=$(awk -v p="$pid" '$1 == p { print $2; exit }' <<<"$panes")
        [[ -n $pane ]] && break
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
      done
    fi
    [[ -n $pane ]] || exit 0

    case $state in
      working | waiting | done) tmux set-option -w -t "$pane" @agent_state "$state" 2>/dev/null ;;
      clear) tmux set-option -wu -t "$pane" @agent_state 2>/dev/null ;;
      # The pane keeps the agent's session id (from the hook's JSON: Claude
      # sends session_id, Cursor conversation_id) and which agent it is, so a
      # tmux restore can resume that exact conversation (see resurrect-extras).
      started)
        id=
        if [[ -n $input ]] && command -v jq >/dev/null 2>&1; then
          id=$(jq -r '.session_id // .conversation_id // empty' <<<"$input" 2>/dev/null)
        fi
        case $agent in claude | agent) ;; *) exit 0 ;; esac
        if [[ $id =~ ^[A-Za-z0-9-]+$ ]]; then
          tmux set-option -p -t "$pane" @agent_session "$id" 2>/dev/null
          tmux set-option -p -t "$pane" @agent_cmd "$agent" 2>/dev/null
        fi
        ;;
      ended)
        tmux set-option -pu -t "$pane" @agent_session 2>/dev/null
        tmux set-option -pu -t "$pane" @agent_cmd 2>/dev/null
        ;;
      *) echo "usage: agent-state working|waiting|done|clear|started|ended [claude|agent]" >&2; exit 0 ;;
    esac

    [[ $state == waiting || $state == done ]] || exit 0
    tty=$(tmux display-message -p -t "$pane" '#{pane_tty}' 2>/dev/null)
    [[ -n $tty ]] || exit 0

    # Ring the bell in the agent's pane when it needs attention, so a background
    # window's tab gets highlighted (monitor-bell).
    printf '\a' >"$tty" 2>/dev/null

    # Send a desktop notification (OSC 777, wrapped for tmux passthrough, which
    # needs allow-passthrough all), unless a focused client is already showing
    # this window. These are the only agent notifications: Claude Code's own
    # channel is off, so its 60s idle reminder never reaches the desktop.
    IFS=$'\t' read -r active where < <(tmux display-message -p -t "$pane" $'#{window_active}\t#{session_name}:#{window_name}' 2>/dev/null)
    if [[ $active == 1 ]] && tmux list-clients -t "$pane" -F '#{client_flags}' 2>/dev/null | grep -q focused; then
      exit 0
    fi
    if [[ $state == done ]]; then
      title="Agent done" body=$where
    else
      # The hook's message says what the agent needs ("Claude needs your permission to use Bash").
      title="Agent needs you" body=
      if [[ -n $input ]] && command -v jq >/dev/null 2>&1; then
        body=$(jq -r '.message // empty' <<<"$input" 2>/dev/null)
      fi
      body="$where${body:+: $body}"
    fi
    body=${body//[;$'\a'$'\e']/}
    printf '\ePtmux;\e\e]777;notify;%s;%s\a\e\\' "$title" "$body" >"$tty" 2>/dev/null
    exit 0
