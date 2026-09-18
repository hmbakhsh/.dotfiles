local eslint_fix_group = vim.api.nvim_create_augroup("EslintFixes", {})

local eslint_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

local oxfmt_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "json",
  "jsonc",
  "json5",
  "yaml",
  "html",
  "vue",
  "css",
  "scss",
  "less",
  "graphql",
  "markdown",
  "mdx",
  "handlebars",
  "toml",
}

local function is_eslint_ft(bufnr)
  return vim.tbl_contains(eslint_filetypes, vim.bo[bufnr].filetype)
end

return {
  -- ensure eslint-lsp is installed via mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local ensure = function(pkg)
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end
      ensure("eslint-lsp")
    end,
  },

  -- use oxfmt CLI as the formatter via conform (replaces prettier)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- register oxfmt as a custom formatter
      opts.formatters = opts.formatters or {}
      opts.formatters.oxfmt = {
        command = "oxfmt",
        args = { "--stdin-filepath", "$FILENAME" },
        stdin = true,
      }

      -- assign oxfmt to all relevant filetypes
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(oxfmt_filetypes) do
        opts.formatters_by_ft[ft] = { "oxfmt" }
      end
    end,
  },

  -- disable typescript-tools formatting so it can't interfere
  {
    "pmizio/typescript-tools.nvim",
    opts = {
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end,
    },
  },

  -- disable jsonls formatting, configure eslint
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

      -- eslint fix-all on save
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

  -- disable none-ls (no longer needed)
  {
    "nvimtools/none-ls.nvim",
    enabled = false,
  },
}
