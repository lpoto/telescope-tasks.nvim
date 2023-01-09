local actions = require "telescope._extensions.tasks.actions"
local telescope_actions = require "telescope.actions"

local mappings = {}

mappings.keys = {
  ["<CR>"] = actions.select_task,
  ["<C-o>"] = actions.selected_task_output,
  ["<C-d>"] = actions.delete_selected_task_output,
  ["<C-k>"] = telescope_actions.preview_scrolling_up,
  ["<C-j>"] = telescope_actions.preview_scrolling_down,
}

---@param prev_buf number|nil
---@return function: Attach mappings function
function mappings.get_attach_mappings(prev_buf)
  return function(prompt_bufnr, map)
    for key, f in pairs(mappings.keys or {}) do
      if key == "<CR>" then
        telescope_actions.select_default:replace(function()
          f(prompt_bufnr, prev_buf)
        end)
      else
        for _, mode in ipairs { "n", "i" } do
          map(mode, key, function()
            f(prompt_bufnr, prev_buf)
          end)
        end
      end
    end
    return true
  end
end

return mappings
