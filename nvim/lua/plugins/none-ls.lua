local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

return {
  -- ensure prettierd and eslint_d are installed via mason
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local ensure = function(pkg)
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end
      ensure("prettierd")
      ensure("eslint_d")
    end,
  },

  -- bring in the community extras (eslint_d lives here now)
  { "nvimtools/none-ls-extras.nvim" },

  -- configure none-ls for prettier + eslint_d (diagnostics/actions)
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      local null_ls = require("null-ls")

      local eslint_filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      }

      -- extras sources
      local eslint_diag = require("none-ls.diagnostics.eslint_d").with({
        filetypes = eslint_filetypes,
      })
      local eslint_actions = require("none-ls.code_actions.eslint_d").with({
        filetypes = eslint_filetypes,
      })
      -- if you ever want eslint_d formatting too, uncomment:
      -- local eslint_fmt = require("none-ls.formatting.eslint_d").with({
      --   filetypes = eslint_filetypes,
      -- })

      return {
        sources = {
          -- formatting: prettierd only (avoid conflicts)
          null_ls.builtins.formatting.prettierd,

          -- eslint_d from extras
          eslint_diag,
          eslint_actions,
          -- eslint_fmt, -- disabled by default
        },
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end
        end,
      }
    end,
    config = function(_, opts)
      require("null-ls").setup(opts)
    end,
  },
}
