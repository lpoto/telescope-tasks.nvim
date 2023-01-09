## Roadmap

- [x] Display currently available tasks in a telescope picker
- [x] Allow running and killing tasks from the telescope picker
- [x] Show tasks' definitions or output(when available) in the telescope previewer
- [x] Allow opening the task's output in a separate buffer
- [x] Allow toggling the latest output
- [x] Add setup:
  - [x] Allow adding a custom picker setup
  - [x] Add a theme setup field
  - [x] Allow configuring output window:
    - [x] Support displaying output window in a split
    - [x] Support displaying output window in a vertical split
    - [x] Support displaying output in a floating window
- [x] Allow scrolling the task output preview
- [ ] Redo tasks execution so that each step is it's own job
  - [ ] Allow setting task properties for each step individually
  - [ ] Update task and steps info output texts
    - [ ] Make texts span through the whole window width, remove redundant newlines
    - [ ] Update texts highlights
- [ ] Allow auto-generating tasks from project config files
  > Example: _package.json_ scripts
