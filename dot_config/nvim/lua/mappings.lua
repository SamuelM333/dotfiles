require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Neogit
map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit status" })
map("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
map("n", "<leader>gl", "<cmd>Neogit log<cr>", { desc = "Neogit log" })
map("n", "<leader>gh", function()
  require("neogit.buffers.git_command_history"):new():show()
end, { desc = "Neogit git output history" })

-- tmux: C-h/j/k/l cross into tmux panes at the edge of Neovim (vim-tmux-navigator)
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Window/tmux pane left" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Window/tmux pane down" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Window/tmux pane up" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Window/tmux pane right" })
