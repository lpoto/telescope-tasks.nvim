local popup = {}

function popup.open(choices, selection_callback)
  local bufnr = popup.create_buffer(choices)
  local winid = popup.create_window(bufnr, popup.determine_win_size(choices))
  popup.handle_window(bufnr, winid, selection_callback)
end

function popup.create_buffer(choices)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, choices)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "modified", false)
  return buf
end

function popup.create_window(bufnr, height, width)
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "cursor",
    row = 0,
    col = 0,
    anchor = "NW",
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = true,
    noautocmd = true,
  })
  vim.api.nvim_win_set_option(winid, "cursorline", true)
  vim.api.nvim_win_set_option(
    winid,
    "winhl",
    "NormalFloat:TelescopePromptNormal,FloatBorder:TelescopePromptBorder"
  )
  vim.api.nvim_exec("stopinsert", true)
  return winid
end

function popup.handle_window(bufnr, winid, selection_callback)
  vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave", "FocusLost" }, {
    buffer = bufnr,
    callback = function()
      vim.api.nvim_win_close(winid, true)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end,
  })
  for _, k in ipairs({ "<Esc>", "q" }) do
    vim.keymap.set(
      "",
      k,
      function() vim.api.nvim_exec_autocmds("FocusLost", { buffer = bufnr }) end
    )
  end

  vim.keymap.set(
    "",
    "<Tab>",
    function() popup.scroll(bufnr, winid, false) end,
    { buffer = bufnr }
  )
  vim.keymap.set(
    "",
    "<S-Tab>",
    function() popup.scroll(bufnr, winid, true) end,
    { buffer = bufnr }
  )

  vim.keymap.set("", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_exec_autocmds("FocusLost", { buffer = bufnr })
    selection_callback(line)
  end, {
    buffer = bufnr,
  })
end

function popup.determine_win_size(choices)
  local height = math.max(#choices, 1)
  local width = 20
  for _, s in ipairs(choices) do
    if s:len() + 10 > width then width = s:len() + 10 end
  end
  return height, width
end

function popup.scroll(bufnr, winid, up)
  local cursor = vim.api.nvim_win_get_cursor(winid)
  local linenr = cursor[1]
  local lines = vim.api.nvim_buf_line_count(bufnr)

  local new_line = up and linenr - 1 or linenr + 1
  if new_line < 1 then
    new_line = lines
  elseif new_line > lines then
    new_line = 1
  end

  vim.api.nvim_win_set_cursor(winid, { new_line, 0 })
end

return popup
