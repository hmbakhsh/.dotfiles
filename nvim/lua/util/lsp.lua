local M = {}

local function has_lsp_client(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr }))
end

local function first_location(result)
  if not result then
    return nil
  end

  if vim.tbl_islist(result) then
    if vim.tbl_isempty(result) then
      return nil
    end
    return result[1]
  end

  return result
end

function M.peek_definition()
  local params = vim.lsp.util.make_position_params()
  local bufnr = vim.api.nvim_get_current_buf()

  if not has_lsp_client(bufnr) then
    vim.notify("No LSP attached to buffer", vim.log.levels.INFO)
    return
  end

  vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
    if err then
      vim.notify(err.message or "Error requesting definition", vim.log.levels.ERROR)
      return
    end

    local location = first_location(result)
    if not location then
      vim.notify("No definition found", vim.log.levels.INFO)
      return
    end

    vim.lsp.util.preview_location(location, { border = "rounded" })
  end)
end

function M.rename()
  local bufnr = vim.api.nvim_get_current_buf()

  if not has_lsp_client(bufnr) then
    vim.notify("No LSP attached to buffer", vim.log.levels.INFO)
    return
  end

  vim.lsp.buf.rename()
end

return M
