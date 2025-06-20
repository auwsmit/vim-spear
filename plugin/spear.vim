" Spear - similar to a harpoon
" Author:     Austin W. Smith
" Version:    0.11.0

" README: Most of the plugin code is in autoload/spear.vim
" (if you're in the repo directory, you can gf there)

" TODO: try to eliminate tracker by using smarter logic
"       (use '#' buffer and check if window has changed?)
" TODO: optional nvim floating window support
" TODO: something to do with terminal support, idk the details yet
" TODO: give menu a fancy display
" TODO: cleanup empty lists from spear_data directory
" TODO: maybe show a list of all saved lists, a list list if you will
" TODO: ? to show maps

" INITIALIZATION:
" ===============

if exists('g:loaded_spear')
  finish
endif
let g:loaded_spear = 1

" - create a storage folder
" - cache the relevant list
" - start a small buffer/window tracker
" - and setup commands (only if user enabled them)
call spear#init()

" vim: sw=2 fdm=indent
