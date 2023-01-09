local actions = require "telescope._extensions.tasks.actions"
local telescope_actions = require "telescope.actions"

local mappings = {}

mappings.keys = {
  {
    key = {
      { "<CR>", actions.select_task },
    },
    desc = "Run/Kill",
  },
  {
    key = {
      { "<C-o>", actions.selected_task_output },
      { "<C-d>", actions.delete_selected_task_output },
    },
    modes = { "n", "i" },
    desc = "Show/Delete output ",
  },
  {
    key = {
      { "<C-k>", telescope_actions.preview_scrolling_up },
      { "<C-j>", telescope_actions.preview_scrolling_down },
    },
    modes = { "n", "i" },
    desc = "Scroll preview",
  },
}

---@return string: Mappings description
function mappings.get_description()
  local desc = ""
  for _, cfg in ipairs(mappings.keys or {}) do
    local keys = ""
    for _, m in ipairs(cfg.key or {}) do
      if keys:len() > 0 then
        keys = keys .. "/"
      end
      keys = keys .. m[1]
    end
    if not cfg.silent then
      if desc:len() > 0 then
        desc = desc .. ", "
      end
      desc = desc .. keys .. " - " .. cfg.desc
    end
  end
  return desc
end

---@param prev_buf number|nil
---@return function: Attach mappings function
function mappings.get_attach_mappings(prev_buf)
  return function(prompt_bufnr, map)
    for _, cfg in ipairs(mappings.keys or {}) do
      for _, m in ipairs(cfg.key or {}) do
        if m[1] == "<CR>" then
          telescope_actions.select_default:replace(function()
            m[2](prompt_bufnr, prev_buf)
          end)
        else
          for _, mode in ipairs(cfg.modes or {}) do
            map(mode, m[1], function()
              m[2](prompt_bufnr, prev_buf)
            end)
          end
        end
      end
    end
    return true
  end
end

return mappings
