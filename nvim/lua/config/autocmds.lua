-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable markdown diagnostics/warnings but keep formatting
vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
  pattern = { "markdown", "*.md" },
  callback = function(args)
    vim.diagnostic.enable(false, { bufnr = args.buf })
    vim.diagnostic.hide(nil, args.buf)
  end,
})
