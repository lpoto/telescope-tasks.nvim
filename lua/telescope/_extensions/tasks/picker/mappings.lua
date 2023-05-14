local actions = require "telescope._extensions.tasks.picker.actions"
local telescope_actions = require "telescope.actions"

local mappings = {}

mappings.keys = {
  ["<CR>"] = actions.select_task,
  ["e"] = actions.edit_task_file,
  ["o"] = actions.selected_task_output,
  ["r"] = actions.delete_selected_task_output,
  ["d"] = actions.delete_selected_task_output,
  ["<C-a>"] = actions.run_task_and_save_modified_command,
  ["<C-e>"] = actions.run_task_with_modyfiable_command,
  ["<C-o>"] = actions.selected_task_output,
  ["<C-r>"] = actions.delete_selected_task_output,
  ["<C-q>"] = actions.selection_to_qf,
  ["<C-u>"] = telescope_actions.preview_scrolling_up,
  ["<C-d>"] = telescope_actions.preview_scrolling_down,
}

---@param prompt_bufnr number
---@param map function
---@return boolean
function mappings.attach_mappings(prompt_bufnr, map)
  for key, f in pairs(mappings.keys or {}) do
    if key == "<CR>" then
      telescope_actions.select_default:replace(function()
        f(prompt_bufnr)
      end)
    else
      local modes = { "n" }
      if key:sub(1, 2) == "<C" then
        table.insert(modes, "i")
      end
      for _, mode in ipairs(modes) do
        map(mode, key, function()
          f(prompt_bufnr)
        end)
      end
    end
  end
  return true
end

return mappings
