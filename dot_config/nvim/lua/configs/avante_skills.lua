---Discover and load Cursor Agent Skills (.cursor/skills/*/SKILL.md).
---@class AvanteSkill
---@field name string
---@field description string
---@field path string
---@field source "user" | "project"
---@field body string

local M = {}

local USER_SKILLS_ROOT = vim.fs.joinpath(vim.fn.expand("~"), ".cursor", "skills")

---@param content string
---@return string|nil yaml
---@return string body
local function split_frontmatter(content)
  if not content:match("^---\n") then
    return nil, content
  end

  local yaml_end = content:find("\n---\n", 5, true)
  if not yaml_end then
    yaml_end = content:find("\n---%s*$", 5)
    if not yaml_end then
      return nil, content
    end
    return content:sub(5, yaml_end - 1), ""
  end

  -- yaml_end points at the newline before the closing "---"; skip "\n---\n" (5 bytes).
  return content:sub(5, yaml_end - 1), content:sub(yaml_end + 5):gsub("^%s+", "")
end

---@param yaml string
---@param field string
---@return string|nil
local function parse_yaml_field(yaml, field)
  local inline = yaml:match(field .. ":%s*([^\n]+)")
  if inline and not inline:match("^[|>][-+%.]?$") then
    return inline:gsub("%s+$", "")
  end

  local block = yaml:match(field .. ":%s*>?%-?%s*\n(.-)\n[%w_%-]+%s*:")
    or yaml:match(field .. ":%s*>?%-?%s*\n(.+)$")
  if block then
    return block:gsub("%s+$", ""):gsub("\n%s*", " "):gsub("^%s+", "")
  end

  return nil
end

---@param path string
---@return AvanteSkill|nil
local function parse_skill_file(path, source)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local lines = vim.fn.readfile(path)
  if vim.tbl_isempty(lines) then
    return nil
  end

  local content = table.concat(lines, "\n")
  local yaml, body = split_frontmatter(content)
  local folder_name = vim.fn.fnamemodify(path, ":h:t")

  local name = folder_name
  local description = folder_name

  if yaml then
    name = parse_yaml_field(yaml, "name") or name
    description = parse_yaml_field(yaml, "description") or description
  end

  return {
    name = name,
    description = description,
    path = path,
    source = source,
    body = body,
  }
end

---@param skills_root string
---@param source "user" | "project"
---@return table<string, AvanteSkill>
local function scan_skills_dir(skills_root, source)
  local skills = {}

  if vim.fn.isdirectory(skills_root) ~= 1 then
    return skills
  end

  for entry in vim.fs.dir(skills_root) do
    if entry ~= "." and entry ~= ".." then
      local path = vim.fs.joinpath(skills_root, entry, "SKILL.md")
      local skill = parse_skill_file(path, source)
      if skill then
        skills[skill.name] = skill
      end
    end
  end

  return skills
end

---Discover skills from ~/.cursor/skills and .cursor/skills walking up from cwd.
---Project skills override user skills with the same name; nearer ancestors win.
---@return table<string, AvanteSkill>
function M.discover()
  local merged = scan_skills_dir(USER_SKILLS_ROOT, "user")

  local dir = vim.loop.cwd()
  local user_skills_canonical = vim.fs.normalize(USER_SKILLS_ROOT)

  while dir and dir ~= "" do
    local project_root = vim.fs.joinpath(dir, ".cursor", "skills")
    if vim.fs.normalize(project_root) ~= user_skills_canonical then
      local project_skills = scan_skills_dir(project_root, "project")
      for name, skill in pairs(project_skills) do
        merged[name] = skill
      end
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  return merged
end

---@return AvanteSkill[]
function M.list()
  local skills = M.discover()
  local names = vim.tbl_keys(skills)
  table.sort(names)

  local result = {}
  for _, name in ipairs(names) do
    table.insert(result, skills[name])
  end
  return result
end

---Find a skill by name. Prefers the nearest .cursor/skills match from cwd, then user skills.
---@param skill_name string
---@return AvanteSkill|nil
---@return string|nil
function M.find(skill_name)
  local user_skills_canonical = vim.fs.normalize(USER_SKILLS_ROOT)
  local dir = vim.loop.cwd()

  while dir and dir ~= "" do
    local skills_root = vim.fs.joinpath(dir, ".cursor", "skills")
    if vim.fs.normalize(skills_root) ~= user_skills_canonical then
      local path = vim.fs.joinpath(skills_root, skill_name, "SKILL.md")
      local skill = parse_skill_file(path, "project")
      if skill then
        return skill
      end
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  local user_path = vim.fs.joinpath(USER_SKILLS_ROOT, skill_name, "SKILL.md")
  local user_skill = parse_skill_file(user_path, "user")
  if user_skill then
    return user_skill
  end

  return nil, string.format(
    "Skill '%s' not found. Add .cursor/skills/%s/SKILL.md in this project or ~/.cursor/skills/%s/SKILL.md.",
    skill_name,
    skill_name,
    skill_name
  )
end

---@param skill_name string
---@return string|nil body
---@return string|nil error
function M.load(skill_name)
  local skill, err = M.find(skill_name)
  if not skill then
    return nil, err
  end
  return skill.body
end

---@param skill_name string
---@param args string|nil
---@return string|nil
---@return string|nil
function M.build_prompt(skill_name, args)
  local body, err = M.load(skill_name)
  if not body then
    return nil, err
  end

  if args and args ~= "" then
    return body .. "\n\n---\n\nUser request: " .. args
  end

  return body
end

return M
