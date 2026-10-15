---Find node binary, including nvm installs not on GUI Neovim's PATH.
---@return string
local function find_node()
  local node = vim.fn.exepath("node")
  if node ~= "" then
    return node
  end

  local nvm_versions = vim.fn.glob(os.getenv("HOME") .. "/.nvm/versions/node/*/bin/node", false, true)
  table.sort(nvm_versions)
  local latest = nvm_versions[#nvm_versions]
  if latest and vim.fn.executable(latest) == 1 then
    return latest
  end

  return "node"
end

---Resolve mcp-hub CLI entrypoint from a node install.
---@param node string
---@return string|nil
local function find_mcp_hub_cli(node)
  local node_root = vim.fn.fnamemodify(node, ":h:h")
  local cli = node_root .. "/lib/node_modules/mcp-hub/dist/cli.js"
  if vim.fn.filereadable(cli) == 1 then
    return cli
  end
  return nil
end

local node = find_node()
local cli = find_mcp_hub_cli(node)

---@type mcphub.Config
local config = {
  extensions = {
    avante = {
      make_slash_commands = true,
    },
  },
}

-- mcp-hub's bin wrapper uses `#!/usr/bin/env node`, which fails when GUI
-- Neovim has no node on PATH. Invoke node + cli.js directly instead.
if cli then
  config.cmd = node
  config.cmdArgs = { cli }
else
  local mcp_hub = vim.fn.exepath("mcp-hub")
  if mcp_hub == "" then
    local nvm_mcp_hub = vim.fn.fnamemodify(node, ":h") .. "/mcp-hub"
    if vim.fn.executable(nvm_mcp_hub) == 1 then
      mcp_hub = nvm_mcp_hub
    else
      mcp_hub = "mcp-hub"
    end
  end
  config.cmd = mcp_hub
end

return config
