" Spear - similar to a harpoon
" Author:     Austin W. Smith
" Version:    0.3.0

if exists('g:loaded_spear')
  finish
endif
let g:loaded_spear = 1

" TODO: make maps for prev and next file
" TODO: make a file list per working directory
" TODO: create a fancier/prettier fake display buffer somehow
"       - store and read data with readfile and writefile?

let s:spear_is_open = 0
let s:spear_win_height = 8
let s:spear_data_dir = fnamemodify(expand($MYVIMRC), ':h').'/spear_data/'
let s:spear_list_file = s:spear_data_dir.'spear_list.txt'

fun! s:SpearRefresh()
  let spear_id = bufwinnr(s:spear_list_file)
  if spear_id == -1 | return | endif
  if winnr() == spear_id
    edit!
  else
    exec spear_id . 'wincmd w'
    edit!
    if winbufnr(s:last_win) != -1
      exec s:last_win . 'wincmd w'
    endif
  endif
endfun

fun! s:SpearSave()
  silent! write
  let lines = readfile(s:spear_list_file)
  call writefile(lines, s:spear_list_file)
  echo 'Saved Spear List'
  call s:SpearRefresh()
endfun

fun! s:AddFile()
  let line = expand('%:p')
  let lines = readfile(s:spear_list_file)
  if index(lines, line) != -1
    return
  endif

  " check for empty lines
  let blank_idx = index(lines, '')
  if blank_idx != -1
    let lines[blank_idx] = line
  else
    call add(lines, line)
  endif

  call writefile([line], s:spear_list_file, 'a')
  call s:SpearRefresh()
endfun

fun! s:OpenFile(num)
  let saved_file = 0
  let spear_id = bufwinnr(s:spear_list_file)
  if a:num == -1
    let saved_file = getline('.')
  else
    let files = readfile(s:spear_list_file)
    if a:num > len(files) || a:num < 1
      echohl WarningMsg | echo 'No file #' . a:num | echohl None
      return
    endif
    let saved_file = files[a:num-1]
  endif
  if winnr() == spear_id
    call s:CloseSpearMenu()
  endif
  if filereadable(saved_file)
    exec 'silent! edit ' . saved_file
  else
    echohl WarningMsg | echo 'File not found!' | echohl None
    let ask = confirm('Would you like to delete "'.saved_file.'"', "&Yes\n&no", 1)
    if ask == 2 | return | end
    let lines = readfile(s:spear_list_file)
    call remove(lines, a:num-1)
    call writefile(lines, s:spear_list_file)
  endif
endfun

fun! s:DeleteFile(line)
  let lines = readfile(s:spear_list_file)
  let pattern = '\V'.escape(getline(a:line), '\')
  call filter(lines, 'v:val !~# pattern')
  call writefile(lines, s:spear_list_file)
  call s:SpearRefresh()
endfun

fun! s:CreateSpearMenuMaps()
  nnoremap <silent> <buffer> <cr> :call <sid>OpenFile(-1)<cr>
  nnoremap <silent> <buffer> x    :call <sid>DeleteFile('.')<cr>
  nnoremap          <buffer> s    :call <sid>SpearSave()<cr>
  nnoremap <silent> <buffer> q    :close<cr>
endfun

fun! s:SpearTextChanged()
  setlocal nomodified
  " if has('conceal')
  "   setlocal conceallevel=0
  " endif
endfun

fun! s:OpenSpearMenu()
  let s:last_win = winnr()
  let spear_id = bufwinnr(s:spear_list_file)
  if spear_id == -1
    exec 'botright '.s:spear_win_height.'split '.s:spear_list_file
    normal! ggF\l
    set filetype=spear
    set bufhidden=wipe
    setlocal number norelativenumber
    call s:CreateSpearMenuMaps()
    augroup spear_nomodified
      au!
      au TextChanged,TextChangedI <buffer> call <sid>SpearTextChanged()
    augroup END
    " concealing logic/pattern from justinmk's vim-dirvish
    " if has('conceal')
    "   let sep = exists('+shellslash') && !&shellslash ? '\\' : '/'
    "   exe 'syntax match SpearPathHead =.*'.sep.'\ze[^'.sep.']\+'.sep.'\?$= conceal'
    "   setlocal concealcursor=nvc conceallevel=2
    " endif
    let s:spear_is_open = 1
  endif
endfun

fun! s:CloseSpearMenu()
  let spear_id = bufwinnr(s:spear_list_file)
  if winbufnr(s:last_win) != -1
    exec s:last_win . 'wincmd w'
  endif
  exec spear_id . 'wincmd c'
  let s:spear_is_open = 0
endfun

fun! s:ToggleSpearMenu()
  let spear_id = bufwinnr(s:spear_list_file)
  if spear_id == -1
    call s:OpenSpearMenu()
  else
    call s:CloseSpearMenu()
  endif
endfun

fun! s:TrackWindow()
  let spear_id = bufwinnr(s:spear_list_file)
  if s:spear_is_open && spear_id != -1
    if winnr() != spear_id
      let s:last_win = winnr()
    endif
  endif
endfun

augroup spear_window_tracker
  au!
  au WinEnter * call <sid>TrackWindow()
augroup END

" create data storage directory
if !isdirectory(s:spear_data_dir)
  call mkdir(s:spear_data_dir)
endif

command! SpearAdd call <sid>AddFile()
command! SpearToggle call <sid>ToggleSpearMenu()
command! -nargs=1 SpearOpen call <sid>OpenFile(<f-args>)
