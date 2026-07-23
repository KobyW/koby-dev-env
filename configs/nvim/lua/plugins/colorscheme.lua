return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    -- replaces lvim.transparent_window
    transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-night")
  end,
}
