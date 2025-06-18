" Spear - similar to a harpoon
" Author:     Austin W. Smith
" Version:    0.8.0

" TODO: use autoload functions
" TODO: optional :Commands, disabled by default to keep it minimal since
" mappings are the intended way to use Spear
" TODO: remember last position of pinned files when closing/opening
" TODO: cleanup empty lists from spear_data directory
" TODO: add options like save_on_quit, close_when_saved, keep backslashes, etc
" TODO: something to do with terminal support, idk the details yet
" TODO: give menu a fancy display
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
let s:last_file_id = 0
let s:last_win = -1
let s:last_buf = ''

if !isdirectory(s:spear_data_dir)
  call mkdir(s:spear_data_dir)
endif

" VARIABLES FOR USERS TO ADJUST SETTINGS:
" =======================================

" If enabled, a prompt will be shown to delete blank lines or invalid files
" when opened from the Spear List, or with :SpearOpen command/mappings
"
" Does not affect :SpearNext and :SpearPrev
if !exists('g:prompt_delete_blank_lines')
  let g:prompt_delete_blank_lines = 0
endif
if !exists('g:prompt_delete_invalid_files')
  let g:prompt_delete_invalid_files = 0
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

" update the spear list window with current info
fun! s:SpearRefresh()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1 | return | endif
  let orig_win = winnr()
  if orig_win != spear_id
    exec spear_id .'wincmd w'
  endif
  let cursor_pos = getpos('.')
  %delete
  exec 'silent! keepalt read '. s:GetListFile()
  1delete
  call setpos('.', cursor_pos)
  if orig_win != spear_id
    exec orig_win .'wincmd w'
  endif
endfun

fun! s:SpearSave(close)
  let list = s:GetListFile()
  call writefile(getline(1,'$'), list)
  if a:close
    call s:CloseSpearMenu()
    echo 'Saved Spear List'
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
    call s:SpearSave(0)
  endif
  let list = s:GetListFile()
  let lines = readfile(list)

  " " replace \ with / only during duplication checking
  " " disabled for now because it seems pointless
  " let file_slash = substitute(file_to_add, '\', '/', 'g')
  " let lines_slash = []
  " for i_line in lines
  "   call add(lines_slash, substitute(i_line, '\', '/', 'g'))
  " endfor
  " if index(lines_slash, file_slash) != -1
  "   return
  " endif

  " replace \ with /
  let file_to_add = substitute(file_to_add, '\', '/', 'g')
  if index(lines, file_to_add) != -1
    echohl WarningMsg | echo 'File already added' | echohl None
    return
  endif

  " check for empty lines
  let blank_idx = index(lines, '')
  if blank_idx != -1
    let lines[blank_idx] = file_to_add
  else
    call add(lines, file_to_add)
  endif

  call writefile(lines, list)
  call s:SpearRefresh()
  if bufwinnr(s:spear_buf_name) == -1
    echo 'Added "'. expand('%:t') .'" to Spear List'
  endif
endfun

" Opens/edits a file from the spear list:
" Either open file at position a:num,
" or open the selected line in the spear list window
fun! s:OpenFile(num, prompt = 1)
  let saved_file = ''
  let spear_id = bufwinnr(s:spear_buf_name)
  if winnr() == spear_id
    call s:SpearSave(0)
  elseif a:num == 0
    echo 'Spear List is not open, there is no file to select.'
    return
  endif
  let list = s:GetListFile()
  let lines = readfile(list)
  let invalid_file_id = 0
  " get filename
  if a:num == 0
    let saved_file = getline('.')
  else
    if a:num > len(lines) || a:num < 1
      echohl WarningMsg | echo 'No file #'. a:num | echohl None
      return
    endif
    let saved_file = lines[a:num-1]
    let invalid_file_id = index(lines, saved_file)
  endif
  if winnr() == spear_id
    let invalid_file_id = line('.')
    call s:CloseSpearMenu()
  endif

  " open filename
  if filereadable(saved_file)
    if a:prompt
      let s:last_file_id = index(lines,saved_file)
    endif
    exec 'silent! edit '. saved_file
  elseif a:prompt
    echohl WarningMsg | echo 'File not found!' | echohl None
    let msg = ''
    if saved_file == ''
      if !g:prompt_delete_blank_lines | return | endif
      let msg = 'Would you like to delete this blank line?'
    else
      if !g:prompt_delete_invalid_files | return | endif
      let msg = 'Would you like to delete "'. saved_file .'"?'
    endif
    let ask = confirm(msg, "&Yes\n&no", 1)
    if ask == 2 | return | end
    call remove(lines, invalid_file_id-1)
    call writefile(lines, list)
  endif
endfun

" Removes a file from the spear list:
" Either remove the current buffer's name, or the
" currently selected line in the Spear List.
fun! s:DeleteFile()
  if winnr() == bufwinnr(s:spear_buf_name)
    call s:SpearSave(0)
  endif
  let list = s:GetListFile()
  let lines = readfile(list)
  if expand('%') == s:spear_buf_name
    " if spear is open, remove current line (filename) from list
    let line_num = line('.') - 1
    let line = remove(lines, line_num)
    call writefile(lines,list)
    call s:SpearRefresh()
  else
    " if spear is closed, remove current buffer's filename from list
    let line = substitute(expand('%'), '\', '/', 'g')
    let len_before = len(lines)
    call filter(lines, 'v:val !=# line')
    call writefile(lines, list)
    call s:SpearRefresh()
    if bufwinnr(s:spear_buf_name) == -1
      if len_before >= len(lines)
        echo 'Removed "'. fnamemodify(line, ':t') .'" from Spear List'
      else
        echohl WarningMsg | echo 'File not found in list' | echohl None
      endif
    endif
  endif
endfun

" TODO: maybe detect and inform about blank lines?
fun! s:GotoNextPrevFile(direction)
  let list = s:GetListFile()
  let lines = readfile(list)
  let listlen = len(lines)
  let file_id = index(lines, expand('%'))
  " set variables based on moving to prev or next
  let position_check = a:direction == 'next' ?
        \              (s:last_file_id+1 == listlen) : (s:last_file_id == 0)
  let offset         = a:direction == 'next' ? 1     : -1
  let limit_msg      = a:direction == 'next' ? 'end' : 'beginning'
  if position_check
    echo 'At '. limit_msg .' of Spear List'
  else
    let s:last_file_id += offset
    call s:OpenFile(s:last_file_id+1, 0)
  endif
endfun

fun! s:CreateSpearMenuMaps()
  nnoremap <silent> <buffer> <cr> :call <SID>OpenFile(0)<cr>
  nnoremap <silent> <buffer> A    :call <SID>AddFile()<cr>
  nnoremap <silent> <buffer> X    :call <SID>DeleteFile()<cr>
  nnoremap          <buffer> s    :call <SID>SpearSave(1)<cr>
  nnoremap <silent> <buffer> q    :close<cr>
endfun

fun! s:OpenSpearMenu()
  let s:last_buf = expand('%:p')
  let s:last_win = winnr()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1
    exec 'botright '. s:spear_win_height .'split '. s:spear_buf_name
    exec 'silent! keepalt read '. s:GetListFile()
    1delete | normal! ggF\l
    setlocal filetype=spear
    setlocal buftype=acwrite bufhidden=wipe
    setlocal number norelativenumber
    call s:CreateSpearMenuMaps()
    augroup spear_menu_opened
      au!
      au TextChanged,TextChangedI <buffer> setlocal nomodified
      au BufWriteCmd <buffer> call <SID>SpearSave(1)
    augroup END
    let s:spear_is_open = 1
  endif
endfun

" Close spear and return to the previous window.
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
  if s:spear_is_open && spear_id != -1
    if winnr() != spear_id
      if expand('%') != s:spear_buf_name " in case of duplicate spear windows
        let s:last_buf = expand('%')
        let s:last_win = winnr()
      endif
    endif
  endif
endfun

augroup spear_bufwin_tracker
  au!
  au BufEnter * call <SID>Tracker()
augroup END

command! SpearAdd call <SID>AddFile()
command! SpearDelete call <SID>DeleteFile()
command! SpearToggle call <SID>ToggleSpearMenu()
command! -nargs=1 SpearOpen call <SID>OpenFile(<f-args>)
command! SpearNext call <SID>GotoNextPrevFile('next')
command! SpearPrev call <SID>GotoNextPrevFile('prev')
