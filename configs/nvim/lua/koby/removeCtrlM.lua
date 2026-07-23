-- remove "^M" characters from file

local M = {}

function M.remove_ctrl_m()
    vim.cmd([[
        %s/\r//g
    ]])
end

return M
