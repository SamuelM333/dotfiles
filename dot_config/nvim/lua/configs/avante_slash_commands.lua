---Avante slash commands backed by Cursor Agent Skills.
---@class AvanteSlashCommand
---@field name string
---@field description string
---@field details string
---@field shorthelp? string
---@field callback? fun(sidebar: avante.Sidebar, args: string, cb?: fun(args: string): nil): nil

local skills = require("configs.avante_skills")

local M = {}

---Mutable table passed to avante.setup({ slash_commands = M.commands }).
M.commands = {}

---@param sidebar avante.Sidebar
---@param skill_name string
---@param args string
local function run_skill(sidebar, skill_name, args)
  local prompt, err = skills.build_prompt(skill_name, args)
  if not prompt then
    sidebar:update_content(err, { focus = false, scroll = false })
    return
  end

  sidebar:handle_submit(prompt)
end

---@param sidebar avante.Sidebar
---@param args string
local function run_skill_command(sidebar, args)
  local skill_name, rest = args:match("^(%S+)%s*(.*)$")
  if not skill_name or skill_name == "" then
    local lines = { "Usage: /skill <name> [question]", "", "Available skills:" }
    for _, skill in ipairs(skills.list()) do
      local scope = skill.source == "user" and "[user]" or "[project]"
      table.insert(lines, string.format("- %s %s — %s", skill.name, scope, skill.description))
    end
    sidebar:update_content(table.concat(lines, "\n"), { focus = false, scroll = false })
    return
  end

  run_skill(sidebar, skill_name, rest)
end

---@param sidebar avante.Sidebar
local function list_skills(sidebar)
  local lines = { "Cursor skills available from this directory:", "" }
  local found = skills.list()

  if #found == 0 then
    table.insert(lines, "No skills found.")
    table.insert(lines, "")
    table.insert(lines, "Add SKILL.md under:")
    table.insert(lines, "  .cursor/skills/<name>/SKILL.md")
    table.insert(lines, "  ~/.cursor/skills/<name>/SKILL.md")
  else
    for _, skill in ipairs(found) do
      local scope = skill.source == "user" and "user" or "project"
      table.insert(lines, string.format("/%s  (%s)", skill.name, scope))
      table.insert(lines, string.format("  %s", skill.description))
      table.insert(lines, "")
    end
    table.insert(lines, "Or use: /skill <name> [question]")
  end

  sidebar:update_content(table.concat(lines, "\n"), { focus = false, scroll = false })
end

local function make_skill_command(skill)
  local description = skill.description
  if #description > 120 then
    description = description:sub(1, 117) .. "..."
  end

  return {
    name = skill.name,
    description = description,
    details = string.format("Load Cursor skill from %s (%s)", skill.path, skill.source),
    shorthelp = description,
    callback = function(sidebar, args)
      run_skill(sidebar, skill.name, args)
    end,
  }
end

---Rebuild slash commands from discovered skills. Safe to call after DirChanged.
function M.refresh()
  local builtin = {
    {
      name = "skill",
      description = "Load a Cursor skill by name",
      details = "/skill <name> [question] — loads .cursor/skills/<name>/SKILL.md",
      shorthelp = "/skill <name> [question]",
      callback = run_skill_command,
    },
    {
      name = "skills",
      description = "List Cursor skills available here",
      details = "List skills from ~/.cursor/skills and ancestor .cursor/skills directories",
      callback = list_skills,
    },
  }

  local seen = {}
  local next_commands = {}

  for _, command in ipairs(builtin) do
    table.insert(next_commands, command)
    seen[command.name] = true
  end

  for _, skill in ipairs(skills.list()) do
    if not seen[skill.name] then
      table.insert(next_commands, make_skill_command(skill))
      seen[skill.name] = true
    end
  end

  for i = #M.commands, 1, -1 do
    M.commands[i] = nil
  end

  for i, command in ipairs(next_commands) do
    M.commands[i] = command
  end
end

---Initial population for lazy.nvim opts.
function M.get()
  M.refresh()
  return M.commands
end

return M
