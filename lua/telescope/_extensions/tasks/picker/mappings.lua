local actions = require "telescope._extensions.tasks.picker.actions"
local telescope_actions = require "telescope.actions"

local mappings = {}

mappings.keys = {
  ["<CR>"] = actions.select_task,
  ["<C-a>"] = actions.select_task_with_arguments,
  ["<C-o>"] = actions.selected_task_output,
  ["<C-d>"] = actions.delete_selected_task_output,
  ["<C-k>"] = telescope_actions.preview_scrolling_up,
  ["<C-j>"] = telescope_actions.preview_scrolling_down,
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
      for _, mode in ipairs { "n", "i" } do
        map(mode, key, function()
          f(prompt_bufnr)
        end)
      end
    end
  end
  return true
end

return mappings
