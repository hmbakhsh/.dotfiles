return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- LazyVim already provides excellent default LSP keymaps with Telescope integration
      -- If you want to customize keymaps, use Telescope's LSP functions for better UX:
      -- servers = {
      --   ["*"] = {
      --     keys = {
      --       { "gd", function() require("telescope.builtin").lsp_definitions() end, desc = "Go to Definition" },
      --       { "gr", function() require("telescope.builtin").lsp_references() end, desc = "Go to References" },
      --       { "gI", function() require("telescope.builtin").lsp_implementations() end, desc = "Go to Implementation" },
      --       { "gy", function() require("telescope.builtin").lsp_type_definitions() end, desc = "Go to Type Definition" },
      --     },
      --   },
      -- },
    },
  },
}
