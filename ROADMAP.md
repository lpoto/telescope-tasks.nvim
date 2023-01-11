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

- [x] Add task generators
  - [x] All tasks should be added through generators
  - [x] Expose api for defining custom generators

##

- [ ] Optimize generators
  - [x] Add a cache so they are not redundantly run every time
    - [ ] Implement cache cleaner for invalid buffers
  - [x] Support adding filetypes and patterns conditions alongside the generators
  - [ ] Support adding root patterns conditions alongside the generators

##

- [x] Support default generators
- [ ] For the default generators, add parsers to parse the errors in the output to a quickfix list
- [ ] Add default generators
  - [ ] _cargo.toml_ targets
  - [ ] _package.json_ scripts
  - [ ] _Makefile_ targets
  - [ ] _Rakefile_ targets
  - [ ] _Run current file_ based on the filetype
  > _TODO_ add more generators

