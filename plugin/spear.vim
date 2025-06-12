" Spear - similar to a harpoon
" Author:     Austin W. Smith
" Version:    0.1.0
if exists('g:loaded_spear')
  finish
endif
let g:loaded_spear = 1

" TODO: add quick-swap hot keys
" TODO: make commands for mapping
" TODO: remove from list when file not found
" TODO: make a file list per working directory
" TODO: create a fancier/prettier fake display buffer somehow
"       - store and read data with readfile and writefile?

let s:spear_is_open = 0
let s:spear_win_height = 8
let s:spear_data_dir = fnamemodify(expand($MYVIMRC), ':h').'/spear_data/'
let s:spear_list_file = s:spear_data_dir.'spear_list_file.txt'

fun! s:SpearRefresh()
  let spear_id = bufwinnr(s:spear_list_file)
  if spear_id == -1 | return | endif
  if winnr() == spear_id
    edit!
  else
    exec spear_id . 'wincmd w'
    edit!
    if winbufnr(g:last_win) != -1
      exec g:last_win . 'wincmd w'
    endif
  endif
endfun

fun! s:AddFile()
  let line = expand('%:p')
  let has_line = index(readfile(s:spear_list_file), line) != -1
  if has_line
    return
  else
    call writefile([line], s:spear_list_file, 'a')
    call s:SpearRefresh()
  endif
endfun

fun! s:OpenFile()
  let saved_file = getline('.')
  call s:CloseSpearMenu()
  if filereadable(saved_file)
    exec 'silent! edit ' . saved_file
  else
    echo 'File not found!'
    " TODO: remove from list
  endif
endfun

fun! s:DeleteFile()
  let lines = readfile(s:spear_list_file)
  let l:pattern = '\V'.escape(getline('.'), '\')
  let new_lines = filter(lines, 'v:val !~# l:pattern')
  call writefile(new_lines, s:spear_list_file)
  call s:SpearRefresh()
endfun

fun! s:CreateSpearMaps()
  nnoremap <silent> <buffer> <cr> :call <sid>OpenFile()<cr>
  nnoremap <silent> <buffer> x    :call <sid>DeleteFile()<cr>
  nnoremap <silent> <buffer> q    :close<cr>
  nnoremap          <buffer> s    :write<cr>:echo 'Saved Spear List'<cr>
endfun

fun! s:SpearTextChanged()
  setlocal nomodified
  " if has('conceal')
  "   setlocal conceallevel=0
  " endif
endfun

fun! s:OpenSpearMenu()
  let g:last_win = winnr()
  let spear_id = bufwinnr(s:spear_list_file)
  if spear_id == -1
    exec 'botright '.s:spear_win_height.'split '.s:spear_list_file
    set filetype=spear
    set bufhidden=wipe
    call s:CreateSpearMaps()
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
  if winbufnr(g:last_win) != -1
    exec g:last_win . 'wincmd w'
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
      let g:last_win = winnr()
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

nnoremap <silent> <space>s :call <sid>ToggleSpearMenu()<cr>
nnoremap <space>a :call <sid>AddFile()<cr>
