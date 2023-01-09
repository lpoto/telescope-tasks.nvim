## Roadmap

- [x] Display currently available tasks in a telescope picker
- [x] Suport running and killing tasks from the telescope picker
- [x] Show tasks' definitions or output(when available) in the telescope previewer
- [x] Suport opening the task's output in a separate window
- [x] Suport toggling the latest output window
- [x] Add setup
  - [x] Suport adding a custom picker setup
  - [x] Add a theme setup field
  - [x] Suport configuring output window
    - [x] Support displaying output window in a split
    - [x] Support displaying output window in a vertical split
    - [x] Support displaying output in a floating window
- [x] Suport scrolling the task output preview

##

- [ ] Redo tasks execution so that each step is it's own job
  - [ ] Suport setting task properties for each step individually
  - [ ] Update task and steps info output texts
    - [ ] Make texts span through the whole window width, remove redundant newlines
    - [ ] Update texts highlights

##

- [ ] Add task generators
  > All tasks should be added through generators
  - [ ] Expose api for defining custom generators
  - [ ] Generators should have conditions that determine when they should be run
    > This should replace the tasks' patterns and filetypes properties
    - [ ] The conditions should be checked on BufEnter events
    - [ ] The condition should be a function that receives the buffer name as a parameter and returns a boolean
      > A generator is run when it's condition is either nil or returns true

##

- [ ] Add default generators that generate tasks from project config files
  > _Example_: _cargo.toml_ targets or _package.json_ scripts
