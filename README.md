# ---Spear-->

### ⟶Pin and quickly access important files per-project.

I have basically recreated Primeagen's Harpoon nvim plugin from scratch, but in
vimscript. Functions almost identically to Harpoon 2's core functionality.

Still a work in progress, but is fully usable! No fancy extra features or
tmux/terminal integration yet.

### ⟶Why? Harpoon already exists...

This has been fun to make, it's a project learn from, and it works in both
old Vim and Neovim, while Harpoon is exclusive to Neovim.

### ⟶Why not use uppercase/file marks with tabs and/or sessions?

If those work fine for you, then you don't need this plugin, and that's ok! Vim has many awesome built-in features which require no plugin installation or configuration.

Then why use Harpoon or Spear over marks and tabs/sessions?

- Streamlines the process of marks/tabs/sessions.
- Easier to look up and manage the list of files. You can edit and save the list like a normal buffer.
- Just cd to a project to have access to its pinned files, no dealing with session options or files or tabs.
- Has more navigation options, hotkeys are mapped to the order of the list, and you can cycle through the list.
- Can handle more than 26 files across all projects (assuming you need to work on that many projects/files on one system).
- You can still use file marks, tabs, and sessions along side this plugin.

## ⟶Installation

If you wanna try it out, then install via your preferred plugin
manager:

```vim
" vim-plug vimscript
Plug 'auwsmit/vim-spear'
```

```lua
-- lazy.nvim lua
{
    "auwsmit/vim-spear"
}
```

## ⟶Setup

Put mappings like these somewhere in your vim config file(s):

```vim
nnoremap <silent> <Leader>A :call spear#add_file()<CR>
nnoremap <silent> <Leader>X :call spear#remove_file()<CR>
nnoremap <silent> <C-s>     :call spear#toggle_menu()<CR>
nnoremap <silent> <C-h>     :call spear#open_file(1)<CR>
nnoremap <silent> <C-j>     :call spear#open_file(2)<CR>
nnoremap <silent> <C-k>     :call spear#open_file(3)<CR>
nnoremap <silent> <C-l>     :call spear#open_file(4)<CR>
" move to next or previous file in list
nnoremap <silent> <C-S-N>   :call spear#next_prev_file('next')<CR>
nnoremap <silent> <C-S-P>   :call spear#next_prev_file('prev')<CR>
```

```lua
-- with lua
local kmap = vim.keymap.set
local opts = { noremap = true, silent = true }
kmap('n', '<Leader>A', ":call spear#add_file()<CR>", opts)
kmap('n', '<Leader>X', ":call spear#remove_file()<CR>", opts)
kmap('n', '<C-s>',     ":call spear#toggle_menu()<CR>", opts)
kmap('n', '<C-h>',     ":call spear#open_file(1)<CR>", opts)
kmap('n', '<C-j>',     ":call spear#open_file(2)<CR>", opts)
kmap('n', '<C-k>',     ":call spear#open_file(3)<CR>", opts)
kmap('n', '<C-l>',     ":call spear#open_file(4)<CR>", opts)
kmap('n', '<C-S-N>',   ":call spear#next_prev_file('next')<CR>", opts)
kmap('n', '<C-S-P>',   ":call spear#next_prev_file('prev')<CR>", opts)
```

## ⟶How to use

Go to a project directory, add files, and then access them with mappings. Now
you can always access them when you return to the project. Edit and rearrange
the menu list and save it like a normal buffer. Quickly quit or save with `q`
and `s`, and open files with `<CR>`.

The mappings to add and remove the current fil also work on the menu while its open.

Beware that opening a file from the menu will also save any unsaved changes.

## ⟶Settings

Purely optional settings to adjust based on your preferences:

(these are the default values)

```vim
" prompt to delete invalid files from the list.
" by default it will ignore blank lines,
" and edit a new file if it doesn't exist
let g:spear_delete_blank_lines = 0
let g:spear_delete_invalid_files = 0

" close the menu whenever it's manually saved
" (enable this to be more Harpoon-like)
let g:spear_quit_on_save = 0

" always save when the list menu text changes,
" convenient but dangerous
let g:spear_save_on_change = 0

" cycle with the previous/next maps
let g:spear_next_prev_cycle = 0

" use floating window intead of split window
" (neovim only)
let g:spear_use_floating_window = 1

" convert backslashes to forward slashes
" (windows only)
let g:spear_convert_backslashes = 1
```

```lua
-- with lua
vim.g.spear_delete_blank_lines = 0
```

This is a bit pointless for a mapping-focused plugin, but if you want pretty
commands to run, then you can enable this and make mappings this way instead:

```vim
let g:spear_create_commands = 1
nnoremap <silent> <Leader>A :SpearAdd<CR>
nnoremap <silent> <Leader>X :SpearRemove<CR>
nnoremap <silent> <C-s>     :SpearToggle<CR>
nnoremap <silent> <C-h>     :SpearOpen 1<CR>
nnoremap <silent> <C-j>     :SpearOpen 2<CR>
nnoremap <silent> <C-k>     :SpearOpen 3<CR>
nnoremap <silent> <C-l>     :SpearOpen 4<CR>
nnoremap <silent> <C-S-N>   :SpearNext<CR>
nnoremap <silent> <C-S-P>   :SpearPrev<CR>
```
