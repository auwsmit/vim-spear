# Spear

### Pin and quickly access important files per-project.

Basically recreating Primeagen's Harpoon 2 nvim plugin from scratch, but in
vimscript.

It functions almost identically to Harpoon 2. Still a work in progress.

### Why? Harpoon already exists...

This has been fun to make, it's a project learn from, and it works in both
old Vim and Neovim, while Harpoon is exclusive to Neovim.

## Installation

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

## Setup

Put mappings like these somewhere in your vim config file(s):

```vim
" all neatly around home row
nnoremap <silent> <Leader>A :call spear#add_file()<cr>
nnoremap <silent> <Leader>X :call spear#remove_file()<cr>
nnoremap <silent> <c-m>     :call spear#toggle_menu()<cr>
nnoremap <silent> <c-h>     :call spear#open_file(1)<cr>
nnoremap <silent> <c-j>     :call spear#open_file(2)<cr>
nnoremap <silent> <c-k>     :call spear#open_file(3)<cr>
nnoremap <silent> <c-l>     :call spear#open_file(4)<cr>
" < previous, and > next in the list
nnoremap <silent> <c-.>     :call spear#next_prev_file('next')<cr>
nnoremap <silent> <c-,>     :call spear#next_prev_file('prev')<cr>
```

```lua
-- with lua
local kmap = vim.keymap.set
local opts = { noremap = true, silent = true }
kmap('n', '<Leader>A', ":call spear#add_file()<CR>", opts)
kmap('n', '<Leader>X', ":call spear#remove_file()<CR>", opts)
kmap('n', '<C-m>',     ":call spear#toggle_menu()<CR>", opts)
kmap('n', '<C-h>',     ":call spear#open_file(1)<CR>", opts)
kmap('n', '<C-j>',     ":call spear#open_file(2)<CR>", opts)
kmap('n', '<C-k>',     ":call spear#open_file(3)<CR>", opts)
kmap('n', '<C-l>',     ":call spear#open_file(4)<CR>", opts)
kmap('n', '<C-.>',     ":call spear#next_prev_file('next')<CR>", opts)
kmap('n', '<C-,>',     ":call spear#next_prev_file('prev')<CR>", opts)
```

## Settings

Purely optional settings to adjust based on your preferences:

(these are the default values)

```vim
" prompt to delete invalid files
let g:spear_delete_blank_lines = 0
let g:spear_delete_invalid_files = 0

" close the menu whenever it's manually saved
let g:spear_quit_on_save = 0

" always save when the list menu changes
let g:spear_save_on_change = 0

" cycle with the previous/next maps
let g:spear_prev_next_cycle = 0

" convert backslashes to forward slashes
" (windows only)
let g:spear_convert_backslashes = 1
```

```lua
-- with lua
vim.g.spear_delete_blank_lines = 0
```

This is a bit pointless for a mapping-focused plugin, but if you want pretty
commands to run, then you can enable this and make mappings this way as well:

```vim
let g:spear_create_commands = 1
nnoremap <silent> <Leader>A :SpearAdd<CR>
nnoremap <silent> <Leader>X :SpearRemove<CR>
nnoremap <silent> <C-m>    :SpearToggle<CR>
nnoremap <silent> <C-h>    :SpearOpen 1<CR>
nnoremap <silent> <C-j>    :SpearOpen 2<CR>
nnoremap <silent> <C-k>    :SpearOpen 3<CR>
nnoremap <silent> <C-l>    :SpearOpen 4<CR>
nnoremap <silent> <C-.>    :SpearNext<CR>
nnoremap <silent> <C-,>    :SpearPrev<CR>
```
