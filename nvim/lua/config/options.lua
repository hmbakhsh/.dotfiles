-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Configure diagnostics
vim.diagnostic.config({
  virtual_text = true, -- Show diagnostics inline
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
