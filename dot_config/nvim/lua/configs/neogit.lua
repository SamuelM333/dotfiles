---@module 'neogit'
---@type neogit.Config
return {
  -- Use system git for Neogit UI. git-via-poetry is too slow (poetry startup per git call)
  -- and can make Neogit feel frozen in pyproject.toml repos.
  git_executable = "git",
  -- Keep hook/pre-commit output visible (default console auto-closes and is easy to miss)
  auto_close_console = false,
  auto_show_console = true,
  auto_show_console_on = "output",
  console_timeout = 500,
  preview_buffer = {
    kind = "split_below",
  },
  integrations = {
    telescope = false,
    snacks = true,
    diffview = true,
  },
  -- Open in a tab by default; use :Neogit kind=floating for a floating window
  kind = "tab",
  disable_line_numbers = true,
  disable_relative_line_numbers = true,
  signs = {
    hunk = { "", "" },
    item = { ">", "v" },
    section = { ">", "v" },
  },
}
