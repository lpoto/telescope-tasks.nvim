local hi = {}

local match_exited_output_text_hi
local hi_output_float

function hi.set_output_window_highlights(winid)
  match_exited_output_text_hi(winid)
  hi_output_float(winid)
end

function hi.set_previewer_highlights(winid)
  match_exited_output_text_hi(winid)

  vim.api.nvim_win_set_option(
    winid,
    "winhl",
    "TelescopePreviewNormal:Normal,NormalNC:Normal"
  )
end

match_exited_output_text_hi = function(winid)
  pcall(vim.api.nvim_win_call, winid, function()
    vim.fn.matchadd("Statement", "^\\[Process exited .*\\]$")
    vim.fn.matchadd("Function", "^\\[Process exited 0\\]$")
  end)
end

hi_output_float = function(winid)
  vim.api.nvim_win_set_option(
    winid,
    "winhl",
    "FloatBorder:TelescopePromptBorder,FloatTitle:TelescopePromptTitle,NormalFloat:TelescopePromptNormal"
  )
end

return hi
