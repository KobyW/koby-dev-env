-- Koby's Neovim config (migrated from LunarVim)
-- Plugins live in lua/plugins/, custom modules in lua/koby/, LSP settings in lsp/

vim.g.mapleader = " "
vim.g.maplocalleader = " "

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.fileformat = "unix"
vim.opt.fileformats = { "unix", "dos" }
vim.opt.cmdheight = 0
vim.opt.termguicolors = true
vim.opt.cursorline = true -- required by modicator
vim.opt.signcolumn = "yes"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true

---------------------------------------------------------------------------
-- Autocmds
---------------------------------------------------------------------------
-- Stop auto-continuation of comments on new lines
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType" }, {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Show the cmdline while recording a macro (cmdheight is 0 otherwise)
vim.api.nvim_create_autocmd("RecordingEnter", { command = "set cmdheight=1" })
vim.api.nvim_create_autocmd("RecordingLeave", { command = "set cmdheight=0" })

---------------------------------------------------------------------------
-- Keymaps (which-key group labels are in lua/plugins/whichkey.lua)
---------------------------------------------------------------------------
local map = vim.keymap.set

map("n", "<leader>a", ":%y+<CR>", { desc = "Yank entire file to clipboard", silent = true })
map("n", "<leader>R", function() vim.fn.feedkeys(":%s/", "n") end, { desc = "Search and replace" })
map("n", "<leader>S", ":source ~/.config/nvim/init.lua<CR>", { desc = "Source config" })

map("n", "<leader>w", ":w<CR>", { desc = "Save", silent = true })
map("n", "<leader>q", ":q<CR>", { desc = "Quit", silent = true })
map("n", "<leader>/", "gcc", { desc = "Toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "Toggle comment", remap = true })

-- Koby custom modules
map("n", "<leader>m", function() require("koby.diagcopy").copy_diagnostics() end, { desc = "Copy diagnostics" })
map("n", "<leader>kj", function() require("koby.diagcopy").copy_diagnostics() end, { desc = "Copy diagnostics" })
map("n", "<leader>kz", function() require("koby.clipboardToReg").set_clipboard_to_register() end, { desc = "Clipboard to z register" })
map("n", "<leader>km", function() require("koby.removeCtrlM").remove_ctrl_m() end, { desc = "Remove ^M characters" })

---------------------------------------------------------------------------
-- lazy.nvim bootstrap
---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  rocks = { enabled = false },
  change_detection = { notify = false },
})
