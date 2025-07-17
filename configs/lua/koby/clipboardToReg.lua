local M = {}
function M.set_clipboard_to_register()
    local clipboard_contents = vim.fn.getreg('+')
    vim.fn.setreg('z', clipboard_contents)
end
return M
