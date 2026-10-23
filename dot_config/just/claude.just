# Claude Code remote control in the current directory, each session in its own git worktree
[no-cd]
claude-rc *args:
    claude remote-control --spawn worktree {{ args }}
