" Spear - similar to a harpoon
" Author:     Austin W. Smith
" Version:    0.7.0

" TODO: make maps for prev and next file
" TODO: remember last position of pinned files when closing/opening
" TODO: cleanup empty lists
" TODO: add options like save_on_quit, close_when_saved, ignore_blank_lines, etc
" TODO: give menu a fancy display
" TODO: ? to show maps

if exists('g:loaded_spear')
  finish
endif
let g:loaded_spear = 1

let s:spear_is_open = 0
let s:spear_win_height = 8
let s:spear_data_dir = fnamemodify(expand($MYVIMRC), ':h') .'/spear_data/'
let s:spear_buf_name = '-Spear List-'
let s:last_win = -1
let s:last_buf = ''

" retrieves file list based on current working directory
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

" update the spear menu with current info
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

fun! s:OpenFile(num)
  let saved_file = ''
  let spear_id = bufwinnr(s:spear_buf_name)
  if winnr() == spear_id
    call s:SpearSave(0)
  endif
  let list = s:GetListFile()
  let lines = readfile(list)
  let blank_line = 0
  " get filename
  if a:num == 0
    let saved_file = getline('.')
  else
    if a:num > len(lines) || a:num < 1
      echohl WarningMsg | echo 'No file #'. a:num | echohl None
      return
    endif
    let saved_file = lines[a:num-1]
  endif
  if winnr() == spear_id
    let blank_line = line('.')
    call s:CloseSpearMenu()
  endif

  " open filename
  if filereadable(saved_file)
    exec 'silent! edit '. saved_file
  else
    echohl WarningMsg | echo 'File not found!' | echohl None
    let msg = ''
    if saved_file == ''
      let msg = 'Would you like to delete this blank line?'
    else
      let msg = 'Would you like to delete "'. saved_file .'"?'
    endif
    let ask = confirm(msg, "&Yes\n&no", 1)
    if ask == 2 | return | end
    call remove(lines, blank_line-1)
    call writefile(lines, list)
  endif
endfun

fun! s:DeleteFile()
  if winnr() == bufwinnr(s:spear_buf_name)
    call s:SpearSave(0)
  endif
  let list = s:GetListFile()
  let lines = readfile(list)
  if expand('%') == s:spear_buf_name
    " if list is open, remove current line from list
    let line_num = line('.') - 1
    let line = remove(lines, line_num)
    call writefile(lines,list)
    call s:SpearRefresh()
  else
    " if list is closed, remove current file from list
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

" TODO: logic for blank lines?
fun! s:NextPrevFile(direction)
  let list = s:GetListFile()
  let lines = readfile(list)
  let file_id = index(lines, expand('%'))
  if a:direction == 'n'
    " next
    if file_id != -1
      if file_id+1 == len(lines)
        echo 'At end of Spear list.'
      else
        call s:OpenFile(file_id+2)
      endif
    else
      call s:OpenFile(1)
    endif
  else
    " previous
    if file_id != -1
      if file_id == 0
        echo 'At beginning of Spear list.'
      else
        call s:OpenFile(file_id)
      endif
    else
      call s:OpenFile(len(lines))
    endif
  endif
endfun

fun! s:NextFile()
  let list = s:GetListFile()
  let lines = readfile(list)
  let file_id = index(lines, expand('%'))
  if file_id != -1
    if file_id+1 == len(lines)
      echo 'At end of Spear list.'
    else
      call s:OpenFile(file_id+2)
    endif
  endif
endfun

fun! s:PrevFile()
  let list = s:GetListFile()
  let lines = readfile(list)
  let file_id = index(lines, expand('%'))
  if file_id != -1
    if file_id == 0
      echo 'At beginning of Spear list.'
    else
      call s:OpenFile(file_id)
    endif
  endif
endfun

fun! s:CreateSpearMenuMaps()
  nnoremap <silent> <buffer> <cr> :call <sid>OpenFile(0)<cr>
  nnoremap <silent> <buffer> A    :call <sid>AddFile()<cr>
  nnoremap <silent> <buffer> X    :call <sid>DeleteFile()<cr>
  nnoremap          <buffer> s    :call <sid>SpearSave(1)<cr>
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
      au BufWriteCmd <buffer> call <sid>SpearSave(1)
    augroup END
    let s:spear_is_open = 1
  endif
endfun

" close spear and return to the previous window
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

" track the previous non-spear buffer/window
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

augroup spear_tracker
  au!
  au BufEnter * call <sid>Tracker()
augroup END

" create data storage directory
if !isdirectory(s:spear_data_dir)
  call mkdir(s:spear_data_dir)
endif

command! SpearAdd call <sid>AddFile()
command! SpearDelete call <sid>DeleteFile()
command! SpearToggle call <sid>ToggleSpearMenu()
command! -nargs=1 SpearOpen call <sid>OpenFile(<f-args>)
command! SpearNext call <sid>NextPrevFile('n')
command! SpearPrev call <sid>NextPrevFile('p')
