local M = {}

M.install_dir = vim.fn.stdpath "data" .. "/site"

-- Neovim 0.12 ships bundled parsers; the tree-sitter CLI (brew: tree-sitter-cli) installs extras.
M.bundled = { "lua", "vim", "vimdoc", "markdown", "markdown_inline" }

-- Optional parsers; installed only when `tree-sitter` is on PATH.
M.parsers = { "luadoc", "printf" }

---@param opts? { quiet?: boolean } quiet skips the missing-CLI notice (used on startup)
function M.install_optional(opts)
  if vim.fn.executable "tree-sitter" ~= 1 then
    if opts and opts.quiet then
      return
    end
    vim.schedule(function()
      vim.notify(
        "tree-sitter CLI not found; using Neovim bundled parsers. To install extras: brew install tree-sitter-cli, then :TSUpdate",
        vim.log.levels.INFO
      )
    end)
    return
  end

  if #M.parsers == 0 then
    return
  end

  require("nvim-treesitter").install(M.parsers)
end

return M
