return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  -- keys match LunarVim muscle memory (<leader>f find files, <leader>s* search)
  keys = {
    { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>st", "<cmd>Telescope live_grep<cr>", desc = "Search text (rg)" },
    { "<leader>sb", "<cmd>Telescope buffers<cr>", desc = "Search buffers" },
    { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Search help" },
    { "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
  },
  opts = {},
}
