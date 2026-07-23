return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    -- same signature-help opt-out as the old LunarVim config
    opts = {
      lsp = {
        signature = {
          enabled = false,
          auto_open = { enabled = false },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "tomorrow_night",
        globalstatus = true,
      },
    },
  },
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    -- colors the line number of the current line by mode
    -- (requires number + cursorline + termguicolors, set in init.lua)
    "mawkler/modicator.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
