# Claude Code remote control in the current directory.
# Runs scripts/claude-rc-{pre,post}.sh around it when the host has them (blade15: RGB off, gaming power + auto fan, caffeine on).
[no-cd]
claude-rc *args:
    #!/usr/bin/env bash
    hooks="{{ justfile_directory() }}/scripts"
    if [ -x "$hooks/claude-rc-pre.sh" ]; then "$hooks/claude-rc-pre.sh"; fi
    trap 'if [ -x "$hooks/claude-rc-post.sh" ]; then "$hooks/claude-rc-post.sh"; fi' EXIT
    claude remote-control {{ args }}
