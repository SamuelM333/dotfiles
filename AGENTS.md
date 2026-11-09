# dotfiles

[chezmoi](https://www.chezmoi.io/) source directory for Samuel's machines (Linux and macOS). It lives at `~/.local/share/chezmoi` and is mirrored to the public GitHub repo [SamuelM333/dotfiles](https://github.com/SamuelM333/dotfiles).

## Repo map

| Path | What |
|---|---|
| `dot_*`, `private_*`, `executable_*`, `*.tmpl` | Managed files, named with chezmoi's source-state attributes (`dot_zshrc.tmpl` → `~/.zshrc`) |
| [.chezmoi.toml.tmpl](.chezmoi.toml.tmpl) | Config template, generates the per-machine data (`.pretty_hostname`, …) |
| [.chezmoidata/](.chezmoidata) | Static template data |
| [.chezmoitemplates/](.chezmoitemplates) | Shared template fragments, pulled in with `{{ template "…" . }}` |
| [.chezmoiexternal.toml.tmpl](.chezmoiexternal.toml.tmpl) | Files and repos chezmoi downloads (ghostty shaders and themes, agent skills into `~/.agents/skills`) |
| [private_dot_claude/](private_dot_claude) | Claude Code (Linux only): `modify_settings.json` merges hooks and defaults into `~/.claude/settings.json`; `skills/` links `~/.claude/skills/<name>` to `~/.agents/skills/<name>` |
| [.chezmoiscripts/](.chezmoiscripts) | `run_*` scripts chezmoi runs on apply |
| [.chezmoiignore](.chezmoiignore) | Per-OS and per-host exclusions, and repo files that aren't dotfiles |
| [patches/](patches) | Diffs applied to external files by the `run_after` script |

Per-host and per-OS differences go in templates (`.chezmoi.os`, `.chezmoi.hostname`, `.pretty_hostname`) or in `.chezmoiignore`, not in separate branches.

## Local workflow

- Edit the source files here, never the target in `$HOME`. Check with `chezmoi diff` before `chezmoi apply`. A target edited by hand gets overwritten on the next apply; bring such changes back with `chezmoi re-add` or `chezmoi add`.
- Render a template without applying it: `chezmoi execute-template < dot_zshrc.tmpl` or `chezmoi cat ~/.zshrc`.
- A file in the repo root that isn't a dotfile (like this one) must be listed in `.chezmoiignore`, or chezmoi copies it into `$HOME`.
- `.envrc` (direnv) sets the git author and `GH_TOKEN` for the `SamuelM333` account. Run `gh` from inside the repo so it picks them up.

## tmux and AI agents

- [dot_config/tmux/tmux.conf](dot_config/tmux/tmux.conf) is the tmux config. Plugins are git repos cloned by chezmoi into `~/.config/tmux/plugins` (see `.chezmoiexternal.toml.tmpl`) and loaded with `run-shell`; there is no TPM.
- `ai [TITLE] [COLOR]` (zsh alias for `just -g ai`, recipe in [dot_config/just/ai.just](dot_config/just/ai.just)) opens or switches to a tmux window TITLE (default: the current directory's name) with Neovim and the agent side by side in `$PWD`. The agent is picked with just's `os()`: `claude` on Linux, Cursor's `agent` on macOS (`AI_AGENT` overrides). `prefix a` prompts for the same.
- Window colors are the `@color` window option, drawn by `window-status-format`. Agent state is `@agent_state`, set by `just -g agent-state working|waiting|done|clear` from agent hooks; `waiting`/`done` ring the bell, and `done` also sends a desktop notification (OSC 777 through tmux passthrough, so `allow-passthrough all`) unless a focused client is showing that window. On Linux, [private_dot_claude/modify_settings.json](private_dot_claude/modify_settings.json) adds those hooks to `~/.claude/settings.json` without touching the rest of the file.
- The cheatsheet on `prefix Space` is plain tmux `display-menu` (no plugin, no build step); edit its menus in [dot_config/tmux/which-key.conf](dot_config/tmux/which-key.conf), one `command-alias` per menu. C-h/j/k/l cross between Neovim and tmux panes through vim-tmux-navigator on both sides (NvChad plugin + mappings in `mappings.lua`).

## Public repo

- **Nothing secret goes in a commit.** No tokens, keys, passwords, private hostnames/IPs or work-specific config. Pull secrets in at apply time from a password manager or environment variable through a template, or leave the file out with `.chezmoiignore`.
- Check the staged diff before every commit (`git diff --cached`).

## Documentation

- `AGENTS.md` describes the repo as it is now and how to work in it. Don't record history, one-off migrations or how a setup was reached; that belongs in commit messages and PRs.

## Git workflow

- **The default branch is `main`.** Ignore the stale `master` branch; branch from the latest `origin/main` (`git fetch origin main && git switch -c <branch> origin/main`).
- **New features always get their own branch and pull request.** Never commit a new feature directly to `main`, and don't pile unrelated features onto an existing feature branch. Push the branch and open a separate PR for it (`gh pr create --base main`).
- **Stage files by name** (`git add dot_zshrc.tmpl .chezmoiignore`). Never use `git add -A`, `git add .` or `git commit -a`: they also pick up local files such as `.claude/` worktrees or scratch output.
- **Don't put `Draft:` or `WIP` in PR titles.** Mark the PR as a draft instead (`gh pr create --draft`, `gh pr ready` when done).
- **Label every new issue.** Pick from the repo's existing labels (`gh label list`), e.g. `bug`, `enhancement`, `documentation`. Don't create new labels without asking.
- **Link issues from the PR.** Put `Closes #N` in the PR description so GitHub closes the issue on merge; mention related issues and PRs by number (`#3`) instead.
- **Tick checklist items as they pass, in PRs and issues.** After testing an item from a PR's or an issue's checklist and it passes, check its box in the description (`- [ ]` → `- [x]`). Tick only what was verified as written: if it passed only in part, or the check itself was wrong, leave it unticked and add a short note on the line. Edit a description with one read and one `gh pr edit <n> --body-file` or `gh issue edit <n> --body-file` per round of checks, not one per item.
  - **Issues also get a comment** with what was tested and the outcome (commands, results, anything that failed or was skipped). A failure goes in that comment too, even when no box changes.
- **GitHub is on the Free plan.** The repo is public, so draft PRs, branch protection and rulesets work. Don't rely on paid features (Team or Enterprise only).
- **Go easy on the API.** `gh` shares a budget of 5,000 REST requests and 5,000 GraphQL points per hour. Get branch state (behind/ahead, heads, diffs) from `git fetch` and local git, not the API. Don't loop over PRs or issues one call each; use one list call (`gh pr list --state open --json number,title,body,headRefName`). Poll checks with `gh pr checks <n> --watch` rather than a tight loop.
- **Keep a PR current with `main` before merging.** Update it on the server with `gh pr update-branch <n> --rebase` (or the PR's **Update branch** button) instead of force-pushing. It uses only what's pushed, so push new commits first.
  - Stacked PRs: update the bottom PR first, then each PR above it. Afterwards check that each branch carries only its own commits (`git log --oneline origin/<base>..origin/<branch>`).
  - After the base PR was squash-merged, merge `main` into the branch instead (`git merge origin/main`, normal push). A rebase would replay the base's old commits and conflict with the squashed copy.
  - A rebase drops merge commits, and with them any conflict fixes made in them. After rebasing a branch that has merge commits, check that those fixes are still in the diff, and redo them as normal commits if not.
  - When a local rebase is unavoidable, restack with `git rebase --fork-point <base> <branch>` and push with `--force-with-lease=<branch>:<expected-sha>`.

## Response style

- **Use the caveman skill by default.** At the start of every session, load the `caveman` skill and follow it for every response until the user says "stop caveman" or "normal mode".
- **Use the caveman skills for their tasks**, without waiting for the slash command:
  - Reviews (a PR, a branch, the diff): `caveman-review`.
  - Getting oriented in the repo, or finding where something lives across files: `caveman-explore`.
  - Questions about the caveman commands: `caveman-help`.
- **Commit messages don't use `caveman-commit`.** It writes Conventional Commits; this repo uses plain imperative subjects (`Drop the caveman-compress skill`).
