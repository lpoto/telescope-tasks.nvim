local enum = {}

enum.TITLE = "Telescope Tasks"

enum.OUTPUT_BUFFER_FILETYPE = "TelescopeTasksOutput"
enum.TELESCOPE_PROMPT_FILETYPE = "TelescopePrompt"

enum.TASKS_AUGROUP = "TelescopeTasks"

enum.OUTPUT = {
  LAYOUT = {
    CENTER = "center",
    BOTTOM = "bottom",
    TOP = "top",
    LEFT = "left",
    RIGHT = "right",
  },
  STYLE = {
    FLOAT = "float",
    SPLIT = "split",
    VSPLIT = "vsplit",
    TAB = "tab",
  },
}

return enum
