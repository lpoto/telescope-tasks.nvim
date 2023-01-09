local hi = {}

local match_inserted_output_text_hi
local hi_output_float

function hi.set_output_window_highlights(winid)
  match_inserted_output_text_hi(winid)
  hi_output_float(winid)
end

function hi.set_previewer_highlights(winid)
  match_inserted_output_text_hi(winid)

  vim.api.nvim_win_set_option(winid, "winhl", "TelescopePreviewNormal:Normal")
  vim.api.nvim_win_set_option(winid, "winhl", "NormalNC:Normal")
end

match_inserted_output_text_hi = function(winid)
  pcall(vim.api.nvim_win_call, winid, function()
    vim.fn.matchadd("Function", "^==> TASK: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Constant", "^==> STEP: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Comment", "^==> CWD: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Statement", "^\\[Process exited .*\\]$")
    vim.fn.matchadd("Function", "^\\[Process exited 0\\]$")
  end)
end

hi_output_float = function(winid)
  vim.api.nvim_win_set_option(winid, "winhl", "NormalFloat:Normal")
end

return hi
