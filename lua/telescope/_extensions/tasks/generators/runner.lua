local enum = require "telescope._extensions.tasks.enum"
local executor = require "telescope._extensions.tasks.executor"

local should_run_generators

local runner = {}

--local generators_updated = false
local current_generators = {}
--local cache = {}
local last_tasks = {}

---Runs all the available generators.
---@return table: The found tasks
function runner.run(buf)
  local ok, tasks = pcall(function()
    if not next(current_generators or {}) then
      return {}
    end

    if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_get_current_buf()
    end
    --local cwd = vim.loop.cwd()
    --local name = vim.api.nvim_buf_get_name(buf)
    --local ftime = vim.fn.getftime(name)

    local found_tasks = {}

    -- NOTE: should run only when current buftype is "" and
    -- the provided buf's buftype is ""
    if not should_run_generators(buf) then
      found_tasks = last_tasks
      --elseif not generators_updated
      --    and cache[buf]
      --    and cache[buf].cwd == cwd
      --    and cache[buf].ftime == ftime
      --    and cache[buf].name == name
      --then
      --  found_tasks = cache[buf].tasks or {}
    else
      vim.notify(
        "SHOULD RUN: " .. vim.api.nvim_buf_get_option(buf, "filetype")
      )
      for _, generator in ipairs(generators or current_generators or {}) do
        if generator:available() then
          found_tasks =
            vim.tbl_extend("force", found_tasks, generator:run() or {})
        end
      end
      --cache[buf] = {
      --  cwd = cwd,
      --  tasks = found_tasks,
      --  name = name,
      --  ftime = ftime,
      --}
      --generators_updated = false
      last_tasks = found_tasks
    end

    found_tasks =
      vim.tbl_extend("force", found_tasks, executor.get_running_tasks() or {})

    return found_tasks
  end)
  if not ok and type(tasks) == "string" then
    vim.notify(tasks, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
    return {}
  end
  return tasks or {}
end

function runner.add_generator(generator)
  table.insert(current_generators, generator)
  generators_updated = true
end

---Checks whether the generators should be run in the provided buffer.
---@param buf number
---@return boolean: Whether the generators should be run
should_run_generators = function(buf)
  local cur_buf = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  local cur_buftype = vim.api.nvim_buf_get_option(cur_buf, "buftype")
  return buftype:len() == 0 and cur_buftype:len() == 0
end

return runner
