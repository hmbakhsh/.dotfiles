return {
  {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      enabled = true,
      trigger_events = { "InsertLeave", "TextChanged" },
      write_all_buffers = false,
      debounce_delay = 750,
      condition = function(buf)
        local fn = vim.fn
        if fn.getbufvar(buf, "&buftype") ~= "" then
          return false
        end
        if fn.getbufvar(buf, "&modifiable") == 0 then
          return false
        end
        return true
      end,
    },
  },
}
