local M = {}

function M.copy_diagnostics()
  local vim = vim
  local api = vim.api
  local fn = vim.fn

  -- Get current buffer and cursor position
  local bufnr = api.nvim_get_current_buf()
  local line_nr = api.nvim_win_get_cursor(0)[1]
  local line_content = api.nvim_get_current_line()
  local filename = fn.expand("%:t")

  -- Get diagnostics for the current line
  local diagnostics = vim.diagnostic.get(bufnr, {lnum = line_nr - 1})

  -- Format the diagnostic message
  local diagnostic_message = diagnostics[1] and diagnostics[1].message or "No diagnostics found"

  -- Create the formatted string
  local formatted_message = string.format(
    "In %s\nI'm getting error/warning:\n%s\nFor line:\n%s",
    filename, diagnostic_message, line_content
  )

  -- Copy to clipboard
  vim.fn.setreg("+", formatted_message)
  print("Copied to clipboard: " .. formatted_message)
end

return M

