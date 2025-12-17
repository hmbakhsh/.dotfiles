local lsp_utils = require("util.lsp")

local function telescope_references()
  local ok_builtin, builtin = pcall(require, "telescope.builtin")
  if not ok_builtin then
    vim.notify("Telescope is not available", vim.log.levels.WARN)
    return
  end

  local themes = require("telescope.themes")
  builtin.lsp_references(themes.get_cursor())
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers["*"] = opts.servers["*"] or {}
      local keys = opts.servers["*"].keys or {}
      opts.servers["*"].keys = keys

      local function remove_key(lhs)
        for i = #keys, 1, -1 do
          if keys[i][1] == lhs then
            table.remove(keys, i)
          end
        end
      end

      remove_key("gr")
      table.insert(keys, {
        "gr",
        telescope_references,
        desc = "Go to References",
        nowait = true,
      })

      remove_key("<leader>cr")
      remove_key("gcr")
      table.insert(keys, {
        "<leader>cr",
        lsp_utils.rename,
        desc = "Rename",
        has = "rename",
      })
      table.insert(keys, {
        "gcr",
        lsp_utils.rename,
        desc = "Rename Symbol",
        has = "rename",
      })

      -- Disable markdown LSP diagnostics but keep formatting
      opts.servers.marksman = {
        handlers = {
          ["textDocument/publishDiagnostics"] = function() end,
        },
      }
    end,
  },
}
