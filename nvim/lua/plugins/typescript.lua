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
}
