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
- [ ] Redo tasks execution so that each step is it's own job
  - [ ] Suport setting task properties for each step individually
  - [ ] Update task and steps info output texts
    - [ ] Make texts span through the whole window width, remove redundant newlines
    - [ ] Update texts highlights
- [ ] Support auto-generating tasks from project config files
  > _Example_: _cargo.toml_ targets or _package.json_ scripts
  - [ ] Expose api for defining custom auto-generators
