" Spear - similar to a harpoon
" Author:     Austin W. Smith

" README: Most of the plugin code is in autoload/spear.vim
" (if you're in the repo directory, you can gf there)

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
