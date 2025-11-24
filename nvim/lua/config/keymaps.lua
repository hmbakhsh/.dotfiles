-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local lsp_utils = require("util.lsp")

-- Better diagnostic navigation
vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic under cursor" })
vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics bufnr=0<cr>", { desc = "List buffer diagnostics" })
vim.keymap.set("n", "<leader>dw", "<cmd>Telescope diagnostics<cr>", { desc = "List workspace diagnostics" })

vim.keymap.set("n", "gp", lsp_utils.peek_definition, { desc = "Peek Definition" })
