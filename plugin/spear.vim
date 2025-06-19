" Spear - similar to a harpoon
" Author:     Austin W. Smith
" Version:    0.9.0

" TODO: optional :Commands, disabled by default to keep it minimal since
" mappings are the intended way to use Spear
" TODO: use autoload functions?
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

let s:spear_is_open = 0
let s:spear_win_height = 8
let s:spear_data_dir = fnamemodify(expand($MYVIMRC), ':h') .'/spear_data/'
let s:spear_buf_name = '-Spear List-'
let s:spear_lines = []
let s:last_file_id = 0
let s:last_win = -1
let s:last_buf = ''

if !isdirectory(s:spear_data_dir)
  call mkdir(s:spear_data_dir)
endif

" VARIABLES FOR USER SETTINGS:
" ============================

" If enabled, a prompt will be shown to delete blank lines or invalid files
" when opened from the Spear List, or with :SpearOpen command/mappings
" ---
" Does not affect :SpearNext and :SpearPrev
if !exists('g:spear_delete_blank_lines')
  let g:spear_delete_blank_lines = 0
endif
if !exists('g:spear_delete_invalid_files')
  let g:spear_delete_invalid_files = 0
endif

" If enabled, Spear will quit when saved (more like Harpoon).
if !exists('g:spear_quit_on_save')
  let g:spear_quit_on_save = 0
endif

" If enabled, Spear will auto-save all changes,
" making manual saving unnecessary.
" ---
" By default, Spear only saves when you add/remove/open a file,
" use the save hotkey, or manually save with a command like :w.
if !exists('g:spear_save_on_change')
  let g:spear_save_on_change = 0
endif

" If enabled, Spear will cycle when reaching the start or
" end of the list when going to the next or previous file.
if !exists('g:spear_prev_next_cycle')
  let g:spear_prev_next_cycle = 0
endif

" If disabled, backslashes are not converted
" to forward slashes in the Spear List
if !exists('g:spear_convert_backslashes')
  let g:spear_convert_backslashes = 1
endif

" FUNCTIONS:
" ==========

" Retrieves file list based on current working directory.
" use shortened cwd + sha256 so file names hopefully don't get too long
fun! s:GetListFile()
  let cwd = substitute(getcwd(), '\', '/', 'g')
  let parts = split(cwd, '/')
  let short_cwd = join(parts[-2:], '_')
  let list = s:spear_data_dir . short_cwd . sha256(cwd) .'.txt'
  if !filereadable(list)
    call writefile([],list)
  endif
  return list
endfun

" Save the spear list and update a local variable array of spear's list
fun! s:SpearSave(msg = 0)
  let list = s:GetListFile()
  call writefile(getline(1,'$'), list)
  let s:spear_lines = readfile(list)
  if a:msg && !g:spear_save_on_change
    echo 'Spear List saved'
  endif
endfun

" Update the spear list window with current info.
fun! s:SpearRefresh()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1 | return | endif
  let orig_win = winnr()
  if orig_win != spear_id
    exec spear_id .'wincmd w'
  endif
  let cursor_pos = getpos('.')
  %delete _
  exec 'silent! keepalt read '. s:GetListFile()
  1delete _
  call setpos('.', cursor_pos)
  if orig_win != spear_id
    exec orig_win .'wincmd w'
  endif
endfun

" Add the current buffer (or whichever buffer was open when Spear was opened)
" to the Spear List.
fun! s:AddFile()
  let file_to_add = expand('%:p')
  if expand('%') == s:spear_buf_name
    if bufexists(s:last_buf)
      let file_to_add = s:last_buf
    else
      echohl WarningMsg | echo 'Cannot find file to add' | echohl None
      return
    endif
  endif

  if winnr() == bufwinnr(s:spear_buf_name)
    call s:SpearSave()
  endif

  " replace \ with / during duplication checking
  let file_slash = substitute(file_to_add, '\', '/', 'g')
  let lines_slash = []
  for i_line in s:spear_lines
    call add(lines_slash, substitute(i_line, '\', '/', 'g'))
  endfor
  if index(lines_slash, file_slash) != -1
    echohl WarningMsg | echo 'File already added' | echohl None
    return
  endif

  " replace \ with / in spear list
  if g:spear_convert_backslashes
    let file_to_add = file_slash
  endif

  " check for empty lines
  let blank_idx = index(s:spear_lines, '')
  if blank_idx != -1
    let s:spear_lines[blank_idx] = file_to_add
  else
    call add(s:spear_lines, file_to_add)
  endif

  call writefile(s:spear_lines, s:GetListFile())
  call s:SpearRefresh()
  if bufwinnr(s:spear_buf_name) == -1
    echo 'Added "'. expand('%:t') .'" to Spear List'
  endif
endfun

" Opens a file from the spear list:
" Either open file at position a:num,
" or open the selected line in the spear list window
fun! s:OpenFile(num, prompt = 1)
  let saved_file = ''
  let spear_id = bufwinnr(s:spear_buf_name)
  if winnr() == spear_id
    call s:SpearSave()
  elseif a:num == 0
    echohl WarningMsg | echo 'Error: Spear is not open to select a file.' | echohl None
    return
  endif
  let invalid_file_id = 0
  " get filename
  if a:num == 0
    let saved_file = getline('.')
  else
    if a:num > len(s:spear_lines) || a:num < 1
      echohl WarningMsg | echo 'No file #'. a:num | echohl None
      return
    endif
    let saved_file = s:spear_lines[a:num-1]
    let invalid_file_id = index(s:spear_lines, saved_file)
  endif
  if winnr() == spear_id
    let invalid_file_id = line('.')
    call s:CloseSpearMenu()
  endif

  " open filename
  if filereadable(saved_file)
    if a:prompt
      " tracking for GotoNexPrevFile()
      let s:last_file_id = index(s:spear_lines, saved_file)
    endif
    exec 'silent! edit '. saved_file
    silent! normal! g`"
  elseif a:prompt
    echohl WarningMsg | echo 'File not found!' | echohl None
    let msg = ''
    if saved_file == ''
      if !g:spear_delete_blank_lines | return | endif
      let msg = 'Would you like to delete this blank line?'
    else
      if !g:spear_delete_invalid_files | return | endif
      let msg = 'Would you like to delete "'. saved_file .'"?'
    endif
    let ask = confirm(msg, "&Yes\n&no", 1)
    if ask == 2 | return | end
    call remove(s:spear_lines, invalid_file_id-1)
    call writefile(s:spear_lines, s:GetListFile())
  endif
endfun

" Removes a file from the spear list:
" Either remove the current buffer's name, or the
" currently selected line in the Spear List.
fun! s:DeleteFile()
  if winnr() == bufwinnr(s:spear_buf_name)
    call s:SpearSave()
  endif
  let list = s:GetListFile()
  let bufname = expand('%')
  let matchstr = ''
  if bufname == s:spear_buf_name
    " if spear is open, remove current line (filename) from list
    let line_num = line('.') - 1
    let line = remove(s:spear_lines, line_num)
    call writefile(s:spear_lines,list)
    call s:SpearRefresh()
  else
    " if spear is closed, remove current buffer's filename from list
    let matchstr = g:spear_convert_backslashes ? s:SlashConvert(bufname) : bufname
    let len_before = len(s:spear_lines)
    call filter(s:spear_lines, 'v:val !=# matchstr')
    call writefile(s:spear_lines, list)
    call s:SpearRefresh()
    if bufwinnr(s:spear_buf_name) == -1
      if len_before >= len(s:spear_lines)
        echo 'Removed "'. fnamemodify(bufname, ':t') .'" from Spear List'
      else
        echohl WarningMsg | echo 'File not found in list' | echohl None
      endif
    endif
  endif
endfun

" Open the next or previous file in the Spear List.
fun! s:GotoNextPrevFile(direction)
  let listlen = len(s:spear_lines)
  let file_id = index(s:spear_lines, expand('%'))
  " set variables based on moving to prev or next
  let position_check = (a:direction == 'next' ? (s:last_file_id+1 == listlen) : (s:last_file_id == 0))
  let offset         = (a:direction == 'next' ? 1 : -1)
  if position_check
    if g:spear_prev_next_cycle
      let s:last_file_id = (a:direction == 'next' ? 0 : listlen-1)
      call s:OpenFile(s:last_file_id+1, 0)
      let msg = a:direction == 'prev' ? 'end' : 'beginning'
      echo 'Cycled to '. msg .' of Spear List'
    else
      let msg = a:direction == 'next' ? 'end' : 'beginning'
      echo 'At '. msg .' of Spear List'
    endif
  else
    let s:last_file_id += offset
    call s:OpenFile(s:last_file_id+1, 0)
    echo 'Moved to file '. (s:last_file_id+1) .' of Spear List'
  endif
endfun

fun! s:CreateSpearMenuMaps()
  nnoremap <silent> <buffer> <cr> :call <SID>OpenFile(0)<cr>
  nnoremap <silent> <buffer> A    :call <SID>AddFile()<cr>
  nnoremap <silent> <buffer> X    :call <SID>DeleteFile()<cr>
  nnoremap <silent> <buffer> q    :call <SID>CloseSpearMenu()<cr>
  nnoremap <silent> <buffer> s    :call <SID>SpearSaveMapHelper()<cr>
endfun

fun! s:SpearSaveMapHelper()
  if g:spear_save_on_change | return | endif
  call s:SpearSave(1)
  if g:spear_quit_on_save
    call s:CloseSpearMenu()
  endif
endfun

fun! s:OpenSpearMenu()
  let s:last_buf = expand('%:p')
  let s:last_win = winnr()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1
    let is_open_id = index(s:spear_lines, substitute(expand('%'), '\', '/', 'g'))
    exec 'botright '. s:spear_win_height .'split '. s:spear_buf_name
    exec 'silent! keepalt read '. s:GetListFile()
    1delete _
    if is_open_id == -1
      normal! gg
    else
      exec 'normal! '.(is_open_id+1).'G'
    endif
    setlocal filetype=spear
    setlocal buftype=acwrite bufhidden=wipe
    setlocal number norelativenumber
    call s:CreateSpearMenuMaps()
    " Hacky solution to prevent :wq quitting
    " the next window after BufWriteCmd fires.
    " might remove :w saving entirely in favor of only hotkey & auto saving
    if g:spear_quit_on_save
      cnoreabbrev <buffer> wq w
    endif
    augroup spear_menu_opened
      au!
      au TextChanged,TextChangedI <buffer>
            \   setlocal nomodified
            \ | if g:spear_save_on_change
            \ |   call <SID>SpearSave()
            \ | endif

      au BufWriteCmd <buffer>
            \   call <SID>SpearSave(1)
            \ | if g:spear_quit_on_save
            \ |   call <SID>CloseSpearMenu()
            \ | endif
    augroup END
    let s:spear_is_open = 1
  endif
endfun

fun! s:CloseSpearMenu()
  let spear_id = bufwinnr(s:spear_buf_name)
  if winbufnr(s:last_win) != -1
    exec s:last_win . 'wincmd w'
  endif
  exec spear_id . 'wincmd c'
  let s:spear_is_open = 0
endfun

fun! s:ToggleSpearMenu()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1
    call s:OpenSpearMenu()
  else
    call s:CloseSpearMenu()
  endif
endfun

" Track the previous non-spear buffer/window.
fun! s:Tracker()
  let spear_id = bufwinnr(s:spear_buf_name)
  let bufname = expand('%')
  if s:spear_is_open && spear_id != -1
    if winnr() != spear_id
      if bufname != s:spear_buf_name " in case of duplicate spear windows
        let s:last_buf = bufname
        let s:last_win = winnr()
      endif
      let spear_file_id = index(s:spear_lines, bufname)
      if spear_file_id != -1
        " tracking for GotoNexPrevFile()
        let s:last_file_id = spear_file_id
      endif
    endif
  endif
endfun

" POST SCRIPT INIT:
" =================

augroup spear_bufwin_tracker
  au!
  au BufEnter * call <SID>Tracker()
augroup END

command! SpearAdd call <SID>AddFile()
command! SpearDelete call <SID>DeleteFile()
command! SpearToggle call <SID>ToggleSpearMenu()
command! -nargs=1 SpearOpenFile call <SID>OpenFile(<f-args>)
command! SpearNext call <SID>GotoNextPrevFile('next')
command! SpearPrev call <SID>GotoNextPrevFile('prev')

" update local spear list on startup
let s:spear_lines = readfile(s:GetListFile())
