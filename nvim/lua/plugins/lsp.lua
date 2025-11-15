return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Apply these keymaps to all LSP servers
        ["*"] = {
          keys = {
            { "gd", vim.lsp.buf.definition, desc = "Go to Definition", has = "definition" },
            { "gr", vim.lsp.buf.references, desc = "Go to References", has = "references" },
            { "gI", vim.lsp.buf.implementation, desc = "Go to Implementation", has = "implementation" },
            { "gy", vim.lsp.buf.type_definition, desc = "Go to Type Definition", has = "typeDefinition" },
            { "K", vim.lsp.buf.hover, desc = "Hover Documentation", has = "hover" },
          },
        },
      },
    },
  },
}
