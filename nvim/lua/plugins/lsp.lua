local lsp_utils = require("util.lsp")

local function telescope_references()
  local builtin = require("telescope.builtin")
  local themes = require("telescope.themes")
  builtin.lsp_references(themes.get_cursor())
end

-- Set up LSP keymaps when LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("CustomLspKeymaps", { clear = true }),
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set("n", "gr", telescope_references, vim.tbl_extend("force", opts, { desc = "Go to References", nowait = true }))
    vim.keymap.set("n", "<leader>cr", lsp_utils.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
    vim.keymap.set("n", "gcr", lsp_utils.rename, vim.tbl_extend("force", opts, { desc = "Rename Symbol" }))
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = function(_, opts)

      -- Disable markdown LSP diagnostics but keep formatting
      opts.servers.marksman = {
        handlers = {
          ["textDocument/publishDiagnostics"] = function() end,
        },
      }
    end,
  },
}
