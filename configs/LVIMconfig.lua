-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- Set default file format to Unix (LF)
vim.opt.fileformat = "unix"

-- Set Relative Line Numbers
vim.opt.relativenumber = true
vim.opt.number = true

-- Set file formats to try when reading and writing files
vim.opt.fileformats = { "unix", "dos" }

-- Adding terminal option
lvim.builtin.which_key.mappings["t"] = {
  name = "+Terminal  & tailwind",
  a = {"<cmd>TailwindConcealToggle<cr>", "Toggle Tailwind Conceal"},
  f = { "<cmd>ToggleTerm<cr>", "Floating terminal" },
  v = { "<cmd>2ToggleTerm size=30 direction=vertical<cr>", "Split vertical" },
  h = { "<cmd>2ToggleTerm size=30 direction=horizontal<cr>", "Split horizontal" },
}

-- Function to open a search and replace prompt
local function search_and_replace()
  -- This will prepopulate the command line with ':%s/' and leave the user in command-line mode
  vim.fn.feedkeys(':%s/', 'n')
end

-- Search and Replace
lvim.keys.normal_mode["<leader>R"] = search_and_replace
lvim.builtin.which_key.mappings["R"]= {
  name = "Search and Replace"
}

-- Source lvim config (this file)
lvim.keys.normal_mode["<leader>S"] = ":source ~/.config/lvim/config.lua<CR>"

-- Copy entire file to sys clipboard
lvim.keys.normal_mode["<leader>a"] = ":%y+<CR>"
-- nvim equiv:
-- vim.api.nvim_set_keymap('n', '<leader>a', ':%y+<CR>', { noremap = true, silent = true })

-- Aggressively remove 'c' flag from formatoptions to stop auto-commenting new lines
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "FileType"}, {
  pattern = "*",
  callback = function()
    -- Remove 'c' to stop continuation of comments, 'r' to stop continuation of comments with enter in insert mode,
    -- and 'o' to stop continuation of comments with 'o' or 'O' in normal mode.
    vim.opt.formatoptions:remove({"c", "r", "o"})
  end,
})

lvim.plugins = {
    -- Ensure nui.nvim is added before noice.nvim
    {"MunifTanjim/nui.nvim"},
    {"folke/noice.nvim",
        requires = "MunifTanjim/nui.nvim",
        config = function()
            require("noice").setup()
        end
    },
    {"windwp/nvim-ts-autotag"},
    {"luckasRanarison/tailwind-tools.nvim"},
}

-- tailwind-tools config:
require("tailwind-tools").setup({
 document_color = {
    enabled = true,
    kind = "inline",
    inline_symbol = "󰝤 ",
    debounce = 200,
 },
 conceal = {
    enabled = false,
    symbol = "󱏿",
    highlight = {
      fg = "#38BDF8",
    },
 },
 custom_filetypes = {} -- Add any custom filetypes here
})


-- set current clipboard contents to 'p' register

-- Koby - personal keybindings
lvim.builtin.which_key.mappings["k"] = {
  name = "+Koby",
  j = {"<cmd>lua require('koby/diagcopy').copy_diagnostics()<cr>", "Copy diagnostics"},
  z = {"<cmd>lua require('koby/clipboardToReg').set_clipboard_to_register()<cr>", "Set clipboard to z register"},
  m = {"<cmd>lua require('koby/removeCtrlM').remove_ctrl_m()<cr>", "Remove all ^M characters"},
}

-- transparent window enable
lvim.transparent_window = true

-- Diagnostic copy -> format message
-- local diagcopy = require("koby.diagcopy");
lvim.keys.normal_mode["<leader>m"] = ":lua require('koby.diagcopy').copy_diagnostics()<CR>"

-- Increase cmdheight when starting to record a macro
vim.cmd [[ autocmd RecordingEnter * set cmdheight=1 ]]

-- Reset cmdheight when stopping the recording of a macro
vim.cmd [[ autocmd RecordingLeave * set cmdheight=0 ]]
