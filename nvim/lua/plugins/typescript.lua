local ts_filetypes = {
  typescript = true,
  typescriptreact = true,
  javascript = true,
  javascriptreact = true,
  ["typescript.tsx"] = true,
  ["javascript.jsx"] = true,
}

-- Use TSToolsGoToSourceDefinition which skips .d.ts files and imports
local function goto_ts_source_definition()
  -- Try TSToolsGoToSourceDefinition first (from typescript-tools.nvim)
  local ok = pcall(vim.cmd, "TSToolsGoToSourceDefinition")
  if not ok then
    -- Fallback to standard LSP definition
    vim.lsp.buf.definition()
  end
end

-- Set up the keymap when typescript-tools LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("TypeScriptGotoDefinition", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "typescript-tools" then
      vim.keymap.set("n", "gd", goto_ts_source_definition, { buffer = event.buf, desc = "Go to Source Definition" })
    end
  end,
})

return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
      settings = {
        separate_diagnostic_server = true,
        publish_diagnostic_on = "insert_leave",
        expose_as_code_action = "all",
        complete_function_calls = true,
      },
    },
  },

  {
    "dmmulroy/ts-error-translator.nvim",
    config = function()
      require("ts-error-translator").setup()
    end,
  },
}
