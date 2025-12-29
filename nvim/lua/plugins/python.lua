-- Custom gd that skips import lines for Python
local function goto_python_definition()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })

  if vim.tbl_isempty(clients) then
    return vim.lsp.buf.definition()
  end

  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")

  vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result, ctx, config)
    if err or not result then
      return vim.lsp.buf.definition()
    end

    local results = vim.islist(result) and result or { result }
    if #results == 0 then
      return vim.lsp.buf.definition()
    end

    -- Filter out import lines
    local filtered = {}
    for _, item in ipairs(results) do
      local uri = item.targetUri or item.uri
      local range = item.targetRange or item.range
      if uri and range then
        local def_bufnr = vim.uri_to_bufnr(uri)
        if not vim.api.nvim_buf_is_loaded(def_bufnr) then
          pcall(vim.fn.bufload, def_bufnr)
        end
        local line = vim.api.nvim_buf_get_lines(def_bufnr, range.start.line, range.start.line + 1, false)[1] or ""
        local trimmed = vim.trim(line)
        if not (trimmed:match("^import%s") or trimmed:match("^from%s")) then
          table.insert(filtered, item)
        end
      else
        table.insert(filtered, item)
      end
    end

    -- Use filtered results, or fall back to original if all were imports
    local final = #filtered > 0 and filtered or results
    vim.lsp.handlers["textDocument/definition"](err, vim.islist(result) and final or final[1], ctx, config)
  end)
end

-- Set up the keymap when LSP attaches to Python buffers
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PythonGotoDefinition", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "pyright" then
      vim.keymap.set("n", "gd", goto_python_definition, { buffer = event.buf, desc = "Go to Definition (skip imports)" })
    end
  end,
})

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "black" },
      },
    },
  },
}
