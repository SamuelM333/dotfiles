# dotfiles

[chezmoi](https://www.chezmoi.io/) source directory for Samuel's machines (Linux and macOS). It lives at `~/.local/share/chezmoi` and is mirrored to the public GitHub repo [SamuelM333/dotfiles](https://github.com/SamuelM333/dotfiles).

## Repo map

| Path | What |
|---|---|
| `dot_*`, `private_*`, `executable_*`, `*.tmpl` | Managed files, named with chezmoi's source-state attributes (`dot_zshrc.tmpl` → `~/.zshrc`) |
| [.chezmoi.toml.tmpl](.chezmoi.toml.tmpl) | Config template, generates the per-machine data (`.pretty_hostname`, …) |
| [.chezmoidata/](.chezmoidata) | Static template data |
| [.chezmoitemplates/](.chezmoitemplates) | Shared template fragments, pulled in with `{{ template "…" . }}` |
| [.chezmoiexternal.toml](.chezmoiexternal.toml) | Files and repos chezmoi downloads (ghostty shaders and themes) |
| [.chezmoiscripts/](.chezmoiscripts) | `run_*` scripts chezmoi runs on apply |
| [.chezmoiignore](.chezmoiignore) | Per-OS and per-host exclusions, and repo files that aren't dotfiles |
| [patches/](patches) | Diffs applied to external files by the `run_after` script |

Per-host and per-OS differences go in templates (`.chezmoi.os`, `.chezmoi.hostname`, `.pretty_hostname`) or in `.chezmoiignore`, not in separate branches.

## Local workflow

- Edit the source files here, never the target in `$HOME`. Check with `chezmoi diff` before `chezmoi apply`. A target edited by hand gets overwritten on the next apply; bring such changes back with `chezmoi re-add` or `chezmoi add`.
- Render a template without applying it: `chezmoi execute-template < dot_zshrc.tmpl` or `chezmoi cat ~/.zshrc`.
- A file in the repo root that isn't a dotfile (like this one) must be listed in `.chezmoiignore`, or chezmoi copies it into `$HOME`.
- `.envrc` (direnv) sets the git author and `GH_TOKEN` for the `SamuelM333` account. Run `gh` from inside the repo so it picks them up.

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
