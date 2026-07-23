return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- master is the stable/frozen branch with the classic API; main is a rewrite
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "bash", "json", "yaml", "markdown",
          "javascript", "typescript", "tsx", "html", "css", "python",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
}
