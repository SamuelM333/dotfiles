-- Also sets up and enables lua_ls with Neovim's runtime as its library.
require("nvchad.configs.lspconfig").defaults()

-- Servers and their options. Each table is merged on top of nvim-lspconfig's
-- config for that server (cmd, filetypes, root_markers); {} keeps its defaults.
-- Binaries come from the Brewfile, except nixd (install it with Nix).
local servers = {
  bashls = {},
  clangd = {},
  jsonls = {},
  just = {},
  marksman = {},
  nixd = {},
  pyright = {},
  ruff = {},
  terraformls = {},
  texlab = {},
  yamlls = {},
}

-- Servers whose lspconfig cmd is a function (it prefers a project's
-- node_modules/.bin copy), so the binary name can't be read from it.
local bins = {
  jsonls = "vscode-json-language-server",
  yamlls = "yaml-language-server",
}

for name, opts in pairs(servers) do
  vim.lsp.config(name, opts)
  -- Skip servers whose binary isn't installed on this machine, instead of
  -- failing to start them on every matching buffer.
  local cmd = vim.lsp.config[name].cmd
  local bin = bins[name] or (type(cmd) == "table" and cmd[1])
  if not bin or vim.fn.executable(bin) == 1 then
    vim.lsp.enable(name)
  end
end
