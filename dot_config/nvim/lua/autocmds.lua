require "nvchad.autocmds"

-- NvChad's TSInstallAll uses the old ensure_installed opts; wire it to the new API.
vim.api.nvim_create_user_command("TSInstallAll", function()
  require("configs.treesitter").install_optional()
end, { force = true })

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    local plugin = vim.fn.stdpath "data" .. "/lazy/nvim-treesitter"
    local stale_master = vim.uv.fs_stat(plugin .. "/queries/markdown/injections.scm")
      and not vim.uv.fs_stat(plugin .. "/lua/nvim-treesitter/init.lua")
    if stale_master then
      vim.notify(
        "nvim-treesitter is still on the old master branch. Run :Lazy sync, restart Neovim, then :TSUpdate.",
        vim.log.levels.WARN
      )
    end
  end,
})
