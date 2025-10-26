return {
  -- -- install + load black-metal correctly
  -- {
  --   "metalelf0/black-metal-theme-neovim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("black-metal").setup({
  --       theme = "dark-funeral",
  --     })
  --     require("black-metal").load() -- not :colorscheme
  --   end,
  -- },
  --
  -- -- tell LazyVim to use this scheme (stops it defaulting to tokyonight)
  -- {
  --   "LazyVim/LazyVim",
  --   opts = { colorscheme = "immortal" },
  -- },
  --
  -- -- if you explicitly installed other themes, disable them
  -- { "folke/tokyonight.nvim", enabled = false }, -- only if you have it
  -- { "catppuccin/nvim", name = "catppuccin", enabled = false }, -- optional
  --
  -- CATPPUCCIN
  -- {
  --   "LazyVim/LazyVim",
  --   opts = { colorscheme = "catppuccin" },
  -- },
  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   priority = 1000,
  --   config = function()
  --     require("catppuccin").setup({
  --       flavour = "mocha",
  --       transparent_background = false,
  --       integrations = {
  --         treesitter = true,
  --         native_lsp = { enabled = true },
  --         cmp = true,
  --         gitsigns = true,
  --         telescope = true,
  --         nvimtree = true,
  --         which_key = true,
  --       },
  --     })
  --     vim.cmd.colorscheme("catppuccin")
  --   end,
  -- }
  --
  -- OXOCARBON
  -- {
  --   "nyoom-engineering/oxocarbon.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme("oxocarbon")
  --     vim.cmd([[
  --       hi Normal guibg=NONE ctermbg=NONE
  --       hi NormalNC guibg=NONE ctermbg=NONE
  --       hi SignColumn guibg=NONE ctermbg=NONE
  --       hi EndOfBuffer guibg=NONE ctermbg=NONE
  --     ]])
  --   end,
  -- },
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    vim.cmd("colorscheme rose-pine")
    vim.cmd([[
    hi Normal guibg=NONE ctermbg=NONE
    hi NormalNC guibg=NONE ctermbg=NONE
    hi SignColumn guibg=NONE ctermbg=NONE
    hi EndOfBuffer guibg=NONE ctermbg=NONE
  ]])
  end,
}
