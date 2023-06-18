local util = require("telescope-tasks.util")
local executor = require("telescope-tasks.executor")
local State = require("telescope-tasks.model.state")

local should_run_generators

local runner = {}
local state = nil

--local generators_updated = false
local current_generators = {}
local last_tasks = {}

---Runs all the available generators.
---@return table: The found tasks
function runner.run(buf)
  -- NOTE: create a new runner state every time we run,
  -- so the generators may share data and generate tasks faster.
  state = State:new()

  local ok, tasks = pcall(function()
    if not next(current_generators or {}) then
      return {}
    end

    if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_get_current_buf()
    end

    local found_tasks = {}

    local generators_supported = true

    -- NOTE: should run only when current buftype is "" and
    -- the provided buf's buftype is ""
    if not should_run_generators(buf) then
      generators_supported = false
      found_tasks = last_tasks
    else
      for _, generator in ipairs(current_generators or {}) do
        found_tasks =
          vim.tbl_extend("force", found_tasks, generator:run() or {})
      end
      last_tasks = found_tasks
    end

    found_tasks =
      vim.tbl_extend("force", found_tasks, executor.get_running_tasks() or {})

    if not generators_supported and not next(found_tasks or {}) then
      util.warn("Generating tasks is not supported in current buffer")
    end

    return found_tasks
  end)

  state = nil

  if not ok then
    util.error(tasks)
    return {}
  end
  return tasks or {}
end

function runner.add_generators(generators)
  for _, generator in ipairs(generators) do
    table.insert(current_generators, generator)
  end
end

---@return State|nil
function runner.get_state()
  return state
end

---Checks whether the generators should be run in the provided buffer.
---@param buf number
---@return boolean: Whether the generators should be run
should_run_generators = function(buf)
  local cur_buf = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  local cur_buftype = vim.api.nvim_buf_get_option(cur_buf, "buftype")
  return (buftype:len() == 0 or buftype == "nofile")
    and (cur_buftype:len() == 0 or cur_buftype == "nofile")
end

return runner
