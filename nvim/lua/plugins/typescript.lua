local tsserver_clients = {
  vtsls = true,
  tsserver = true,
  denols = true,
  ["typescript-language-server"] = true,
  ["typescript-tools"] = true,
}

local tsserver_filetypes = {
  typescript = true,
  typescriptreact = true,
  tsx = true,
  javascript = true,
  javascriptreact = true,
}

local function get_tsserver_client(bufnr)
  for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if tsserver_clients[client.name] and client.supports_method("textDocument/definition") then
      return client
    end
  end
  return nil
end

local function should_filter_definition(client, ctx, result)
  return client
    and tsserver_clients[client.name]
    and ctx
    and ctx.bufnr
    and tsserver_filetypes[vim.bo[ctx.bufnr].filetype]
    and result
    and not vim.tbl_isempty(result)
end

local function coerce_result_list(result)
  if vim.tbl_islist(result) then
    return result, true
  end
  return { result }, false
end

local function is_import_line(line)
  local trimmed = vim.trim(line or "")
  return trimmed:match("^import%s") ~= nil
end

local function filter_import_definitions(result)
  local filtered = {}
  for _, item in ipairs(result) do
    local uri = item.targetUri or item.uri
    local range = item.targetRange or item.range
    if not uri or not range then
      table.insert(filtered, item)
    else
      local bufnr = vim.uri_to_bufnr(uri)
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        pcall(vim.fn.bufload, bufnr)
      end
      local line = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range.start.line + 1, false)[1]
      if not is_import_line(line) then
        table.insert(filtered, item)
      end
    end
  end
  if #filtered == 0 then
    return result
  end
  return filtered
end

local function goto_ts_definition()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = get_tsserver_client(bufnr)
  local fallback = function()
    return vim.lsp.buf.definition()
  end
  if not tsserver_filetypes[vim.bo[bufnr].filetype] or not client then
    return fallback()
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
  params.context = { includeDeclaration = false }
  local handler = vim.lsp.handlers["textDocument/definition"]
  local responded = false
  vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result, ctx, config)
    responded = true
    if err or not result or (vim.tbl_islist(result) and vim.tbl_isempty(result)) then
      return fallback()
    end
    if handler then
      return handler(err, result, ctx, config)
    else
      return fallback()
    end
  end)

  vim.defer_fn(function()
    if not responded then
      fallback()
    end
  end, 500)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
    "tsx",
  },
  callback = function(event)
    vim.keymap.set("n", "gd", goto_ts_definition, { buffer = event.buf, desc = "Go to Definition" })
  end,
})

return {
  -- Import LazyVim's TypeScript extras
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- TypeScript error translator
  {
    "dmmulroy/ts-error-translator.nvim",
    config = function()
      require("ts-error-translator").setup()
    end,
  },

  -- Prefer source definitions so gd jumps to the implementation file
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.vtsls = opts.servers.vtsls or {}
      local settings = opts.servers.vtsls.settings or {}
      opts.servers.vtsls.settings = vim.tbl_deep_extend("force", settings, {
        typescript = { preferGoToSourceDefinition = true },
        javascript = { preferGoToSourceDefinition = true },
      })

      local orig = opts.handlers and opts.handlers["textDocument/definition"] or vim.lsp.handlers["textDocument/definition"]
      opts.handlers = opts.handlers or {}
      opts.handlers["textDocument/definition"] = function(err, result, ctx, config)
        local client = ctx and ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id)
        if should_filter_definition(client, ctx, result) then
          local list, is_list = coerce_result_list(result)
          list = filter_import_definitions(list)
          if is_list then
            result = list
          else
            result = list[1]
          end
        end
        return orig(err, result, ctx, config)
      end
    end,
  },
}
