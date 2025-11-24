local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local eslint_fix_group = vim.api.nvim_create_augroup("EslintFixes", {})

local eslint_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

local eslint_config_files = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
}

local function is_eslint_ft(bufnr)
  return vim.tbl_contains(eslint_filetypes, vim.bo[bufnr].filetype)
end

return {
  -- ensure prettierd and eslint_d are installed via mason
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
      ensure("eslint_d")
      ensure("eslint-lsp")
    end,
  },

  -- bring in the community extras (eslint_d lives here now)
  { "nvimtools/none-ls-extras.nvim" },

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

      -- extras sources
      local eslint_diag = require("none-ls.diagnostics.eslint_d").with({
        filetypes = eslint_filetypes,
        condition = function(utils)
          return utils.root_has_file(eslint_config_files)
        end,
      })
      local eslint_actions = require("none-ls.code_actions.eslint_d").with({
        filetypes = eslint_filetypes,
        condition = function(utils)
          return utils.root_has_file(eslint_config_files)
        end,
      })
      -- if you ever want eslint_d formatting too, uncomment:
      -- local eslint_fmt = require("none-ls.formatting.eslint_d").with({
      --   filetypes = eslint_filetypes,
      -- })

      return {
        sources = {
          -- formatting: prettierd only (avoid conflicts)
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
