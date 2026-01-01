local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local eslint_fix_group = vim.api.nvim_create_augroup("EslintFixes", {})

local eslint_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

local function is_eslint_ft(bufnr)
  return vim.tbl_contains(eslint_filetypes, vim.bo[bufnr].filetype)
end

return {
  -- ensure prettierd and eslint-lsp are installed via mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local ensure = function(pkg)
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end
      ensure("prettierd")
      ensure("eslint-lsp")
    end,
  },

  -- disable jsonls formatting to let prettierd handle it
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.jsonls = vim.tbl_deep_extend("force", opts.servers.jsonls or {}, {
        settings = {
          json = {
            format = { enable = false },
          },
        },
      })
      opts.servers.eslint = {
        settings = {
          workingDirectory = { mode = "auto" },
        },
      }

      -- setup code action on save for eslint
      opts.setup = opts.setup or {}
      opts.setup.eslint = function()
        require("lazyvim.util").lsp.on_attach(function(client, bufnr)
          if client.name == "eslint" and is_eslint_ft(bufnr) then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              group = eslint_fix_group,
              callback = function()
                vim.cmd("EslintFixAll")
              end,
            })
          end
        end)
      end
    end,
  },

  -- configure none-ls for prettier + eslint_d (diagnostics/actions)
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      local null_ls = require("null-ls")

      -- NOTE: Using ESLint LSP for linting/fixing (configured above), not eslint_d
      -- This avoids duplicate ESLint runs on save

      return {
        sources = {
          -- formatting: prettierd only (eslint handled by eslint LSP)
          null_ls.builtins.formatting.prettierd.with({
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
              "json",
              "jsonc",
            },
          }),
        },
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = bufnr,
                  filter = function(fmt_client)
                    return fmt_client.name == "null-ls"
                  end,
                })
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
