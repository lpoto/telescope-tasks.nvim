local telescope_actions = require "telescope.actions"
local actions = require "telescope._extensions.tasks.actions"

local mappings = {}

mappings.keys = {
  ["<CR>"] = {
    desc = "Run/Kill",
    action = actions.select_task,
  },
  ["<C-o>"] = {
    modes = { "n", "i" },
    desc = "Show output",
    action = actions.selected_task_output,
  },
  ["<C-d>"] = {
    modes = { "n", "i" },
    desc = "Delete output",
    action = actions.delete_selected_task_output,
  },
}

---@return string: Mappings description
function mappings.get_description()
  local desc = ""
  for key, cfg in pairs(mappings.keys) do
    if desc:len() > 0 then
      desc = desc .. ", "
    end
    desc = desc .. key .. " - " .. cfg.desc
  end
  return desc
end

---@param prev_buf number|nil
---@return function: Attach mappings function
function mappings.get_attach_mappings(prev_buf)
  return function(prompt_bufnr, map)
    for key, cfg in pairs(mappings.keys or {}) do
      if key == "<CR>" then
        telescope_actions.select_default:replace(function()
          cfg.action(prompt_bufnr, prev_buf)
        end)
      else
        for _, mode in ipairs(cfg.modes or {}) do
          map(mode, key, function()
            cfg.action(prompt_bufnr, prev_buf)
          end)
        end
      end
    end
    return true
  end
end

return mappings
