-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- Set default file format to Unix (LF)
vim.opt.fileformat = "unix"

-- Set file formats to try when reading and writing files
vim.opt.fileformats = { "unix", "dos" }

-- Adding terminal option
lvim.builtin.which_key.mappings["t"] = {
  name = "+Terminal",
  f = { "<cmd>ToggleTerm<cr>", "Floating terminal" },
  v = { "<cmd>2ToggleTerm size=30 direction=vertical<cr>", "Split vertical" },
  h = { "<cmd>2ToggleTerm size=30 direction=horizontal<cr>", "Split horizontal" },
}

-- Function to open a search and replace prompt
local function search_and_replace()
  -- This will prepopulate the command line with ':%s/' and leave the user in command-line mode
  vim.fn.feedkeys(':%s/', 'n')
end

-- Key mapping
lvim.keys.normal_mode["<leader>R"] = search_and_replace
lvim.builtin.which_key.mappings["R"]= {
  name = "Search and Replace"
}

-- Aggressively remove 'c' flag from formatoptions to stop auto-commenting new lines
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "FileType"}, {
  pattern = "*",
  callback = function()
    -- Remove 'c' to stop continuation of comments, 'r' to stop continuation of comments with enter in insert mode,
    -- and 'o' to stop continuation of comments with 'o' or 'O' in normal mode.
    vim.opt.formatoptions:remove({"c", "r", "o"})
  end,
})
