---@class TelescopeTasksEnum
local enum = {
  TITLE = "Telescope Tasks",

  OUTPUT_BUFFER_FILETYPE = "TelescopeTasksOutput",
  TELESCOPE_PROMPT_FILETYPE = "TelescopePrompt",

  TASKS_AUGROUP = "TelescopeTasks",

  ---@enum
  OUTPUT = {
    ---@enum
    LAYOUT = {
      CENTER = "center",
      BOTTOM = "bottom",
      TOP = "top",
      LEFT = "left",
      RIGHT = "right",
    },
    ---@enum
    STYLE = {
      FLOAT = "float",
      SPLIT = "split",
      VSPLIT = "vsplit",
      TAB = "tab",
    },
  },

  ---@enum
  PRIORITY = {
    ZERO = 0,
    LOW = 10,
    MEDIUM = 50,
    HIGH = 100,
  },

  NIL = "<__TELESCOPE.TASKS.VALUE.NIL__>",
}

return enum
