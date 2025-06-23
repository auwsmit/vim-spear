" PLUGIN GLOBALS:
" ===============
let s:spear_is_open = 0
let s:spear_win_height = 8
let s:spear_data_dir = fnamemodify(expand($MYVIMRC), ':h') .'/spear_data/'
let s:spear_buf_name = '-Spear List-'
let s:spear_lines = []
let s:last_file_id = 0
let s:last_win = -1
let s:last_buf = ''

" VARIABLES FOR USER SETTINGS:
" ============================

" If enabled, a prompt will be shown to delete blank lines or invalid files
" when opened from the Spear List, or with :SpearOpen command/mappings
" |
" Does not affect :SpearNext and :SpearPrev, which skip invalid files
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
" |
" By default, Spear only saves when you add/remove/open a file,
" use the save hotkey, or manually save with a command like :w.
if !exists('g:spear_save_on_change')
  let g:spear_save_on_change = 0
endif

" If enabled, Spear will cycle when reaching the start or
" end of the list when going to the next or previous file.
if !exists('g:spear_next_prev_cycle')
  let g:spear_next_prev_cycle = 0
endif

" If disabled, backslashes are not converted
" to forward slashes in the Spear List
" |
" (Windows only)
if !exists('g:spear_convert_backslashes')
  let g:spear_convert_backslashes = 1
endif

" If enabled, then commands are created at vim startup.
" |
" These are disabled by default because Spear is intended to be used
" quickly with mappings, and so calling functions is good enough for that.
if !exists('g:spear_create_commands')
  let g:spear_create_commands = 0
endif

" SCRIPT FUNCTIONS:
" =================

" For windows, convert backslashes to forward slashes
fun! s:win_path_fix(path)
  if !has('win32') || !g:spear_convert_backslashes
    return a:path
  endif
  return substitute(a:path, '\', '/', 'g')
endfun

" Retrieves file list based on current working directory.
" use shortened cwd + sha256 so file names hopefully don't get too long
fun! s:get_list_file()
  let cwd = substitute(getcwd(), '\', '/', 'g')
  let parts = split(cwd, '/')
  let short_cwd = join(parts[-2:], '_')
  let list = s:spear_data_dir . short_cwd .'_'. sha256(cwd) .'.txt'

  if !filereadable(list)
    call writefile([],list)
  endif

  return list
endfun

" Track the previous non-spear buffer/window.
fun! s:tracker()
  let spear_id = bufwinnr(s:spear_buf_name)
  let bufname = expand('%')

  if s:spear_is_open && spear_id != -1
    if winnr() != spear_id
      if bufname != s:spear_buf_name " in case of duplicate spear windows
        let s:last_buf = bufname
        let s:last_win = winnr()
      endif
      let s:spear_lines = readfile(s:get_list_file())
      let spear_file_id = index(s:spear_lines, s:win_path_fix(bufname))
      if spear_file_id != -1
        " tracking for next_prev_file()
        let s:last_file_id = spear_file_id
      endif
    endif
  endif

endfun

" Buffer-local mappings for the Spear List
fun! s:save_map_helper()
  if g:spear_save_on_change | return | endif
  call spear#save(1)
  if g:spear_quit_on_save
    call spear#close_menu()
  endif
endfun
fun! s:create_menu_maps()
  nnoremap <silent> <buffer> <cr> :call spear#open_file(0)<cr>
  nnoremap <silent> <buffer> q    :call spear#close_menu()<cr>
  if !g:spear_save_on_change
    nnoremap <silent> <buffer> s    :call <SID>save_map_helper()<cr>
  endif
endfun

" MAIN/AUTOLOAD FUNCTIONS:
" ========================

" Setup, create storage folder, cache list, start
" window tracker, and setup commands if enabled by user
fun! spear#init()
  if !isdirectory(s:spear_data_dir)
    call mkdir(s:spear_data_dir)
  endif

  " Cache local spear list on startup
  silent! let s:spear_lines = readfile(s:get_list_file())

  augroup spear_bufwin_tracker
    au!
    au BufEnter * call <SID>tracker()
  augroup END

  if (g:spear_create_commands)
    command!          SpearAdd      call spear#add_file()
    command!          SpearDelete   call spear#remove_file()
    command!          SpearToggle   call spear#toggle_menu()
    command! -nargs=1 SpearOpenFile call spear#open_file(<f-args>)
    command!          SpearNext     call spear#next_prev_file('next')
    command!          SpearPrev     call spear#next_prev_file('prev')
  endif
endfun

" Save the spear list and cache a local copy of spear's list
fun! spear#save(msg = 0)
  let list = s:get_list_file()
  call writefile(getline(1,'$'), list)
  let s:spear_lines = readfile(list)
  if a:msg && !g:spear_save_on_change
    echo 'Spear List saved'
  endif
endfun

" Update the spear list window with current info.
fun! spear#refresh()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1 | return | endif
  let orig_win = winnr()
  if orig_win != spear_id
    exec spear_id .'wincmd w'
  endif
  let cursor_pos = getpos('.')
  %delete _
  exec 'silent! keepalt read '. s:get_list_file()
  1delete _
  call setpos('.', cursor_pos)
  if orig_win != spear_id
    exec orig_win .'wincmd w'
  endif
endfun

" Add the current buffer (or whichever buffer was open when Spear was opened)
" to the Spear List.
fun! spear#add_file()
  let file_to_add = expand('%:p')
  if expand('%') == s:spear_buf_name
    if bufexists(s:last_buf)
      let file_to_add = s:last_buf
    else
      echohl WarningMsg | echo 'Error: Cannot find file to add' | echohl None
      return
    endif
  endif

  if winnr() == bufwinnr(s:spear_buf_name)
    call spear#save()
  endif

  let file_to_add = s:win_path_fix(file_to_add)
  if index(s:spear_lines, file_to_add) != -1
    echohl WarningMsg | echo 'Error: File already added' | echohl None
    return
  endif

  " check for empty lines
  let blank_idx = index(s:spear_lines, '')
  if blank_idx != -1
    let s:spear_lines[blank_idx] = file_to_add
  else
    call add(s:spear_lines, file_to_add)
  endif

  call writefile(s:spear_lines, s:get_list_file())
  call spear#refresh()
  if bufwinnr(s:spear_buf_name) == -1
    echo 'Added "'. expand('%:t') .'" to Spear List'
  endif
endfun

" Opens a file from the spear list:
" Either open file at position a:num,
" or open the current line in the spear list window
" |
" returns 1 if a file was opened, 0 if the none were
fun! spear#open_file(num, newfile = 1, invalid_prompt = 1)
  let saved_file = ''
  let spear_id = bufwinnr(s:spear_buf_name)
  let invalid_file_id = 0

  if winnr() == spear_id
    " save Spear list if it's the active window
    call spear#save()
  elseif a:num == 0
    echohl WarningMsg | echo 'Error: Spear is not open to select a file.' | echohl None
    return 0
  else
    " Spear is closed, and file a:num is being opened
    " update the spear list in case the cwd has changed
    let s:spear_lines = readfile(s:get_list_file())
  endif

  " get filename
  if a:num == 0
    let saved_file = s:win_path_fix(getline('.'))
  else
    if a:num > len(s:spear_lines) || a:num < 1
      echohl WarningMsg | echo 'Error: No file #'. a:num | echohl None
      return
    endif
    let saved_file = s:spear_lines[a:num-1]
    let invalid_file_id = index(s:spear_lines, saved_file)
  endif
  if winnr() == spear_id
    let invalid_file_id = line('.')
    call spear#close_menu()
  endif

  " open filename
  if filereadable(saved_file)
    if a:invalid_prompt
      " tracking for next_prev_file()
      let s:last_file_id = index(s:spear_lines, saved_file)
    endif
    exec 'silent! edit '. saved_file
    silent! normal! g`"
  elseif a:newfile
    exec 'silent! edit '. saved_file
    return 1
  elseif a:invalid_prompt
    echohl WarningMsg | echo 'Error: File not found!' | echohl None
    let msg = ''
    if saved_file == ''
      if !g:spear_delete_blank_lines | return 0 | endif
      let msg = 'Would you like to delete this blank line?'
    else
      if !g:spear_delete_invalid_files | return 0 | endif
      let msg = 'Would you like to delete "'. saved_file .'"?'
    endif
    let ask = confirm(msg, "&Yes\n&no", 1)
    if ask == 2 | return 0 | end
    call remove(s:spear_lines, invalid_file_id-1)
    call writefile(s:spear_lines, s:get_list_file())
  else
    return 0
  endif

  return 1
endfun

" Removes a file from the spear list:
" Either remove the current buffer's name, or the
" currently selected line in the Spear List.
fun! spear#remove_file()
  if winnr() == bufwinnr(s:spear_buf_name)
    call spear#save()
  endif

  let list = s:get_list_file()
  let bufname = expand('%')
  let matchstr = ''

  if bufname == s:spear_buf_name
    " if spear is open, remove current line (filename) from list
    let line_num = line('.') - 1
    let line = remove(s:spear_lines, line_num)
    call writefile(s:spear_lines,list)
    call spear#refresh()
  else
    " if spear is closed, remove current buffer's filename from list
    let matchstr = s:win_path_fix(bufname)
    let len_before = len(s:spear_lines)
    call filter(s:spear_lines, 'v:val !=# matchstr')
    call writefile(s:spear_lines, list)
    call spear#refresh()
    if bufwinnr(s:spear_buf_name) == -1
      if len_before >= len(s:spear_lines)
        echo 'Removed "'. fnamemodify(bufname, ':t') .'" from Spear List'
      else
        echohl WarningMsg | echo 'Error: File not found in list' | echohl None
      endif
    endif
  endif
endfun

" Move to the next or previous file in the list.
" Skips any invalid files.
fun! spear#next_prev_file(direction)
  let s:spear_lines = readfile(s:get_list_file())
  let listlen = len(s:spear_lines)
  if listlen == 0
    echohl WarningMsg | echo 'Error: No list for this directory.' | echohl None
    return
  endif

  let bufname = s:win_path_fix(expand('%'))
  let start_id = s:last_file_id
  let offset = (a:direction == 'next' ? 1 : -1)
  let file_opened = 0
  while (file_opened == 0)
    let is_start = (s:last_file_id   == 0)
    let is_end   = (s:last_file_id+1 == listlen)
    if (is_start && a:direction == 'prev') || (is_end && a:direction == 'next')
      if g:spear_next_prev_cycle
        let s:last_file_id = is_start ? listlen-1 : 0
      else
        let msg = a:direction == 'next' ? 'end' : 'start'
        let file_opened = spear#open_file(s:last_file_id+1, 0, 0)
        if file_opened
          echo 'Reached '. msg .' of Spear List'
          return
        else
          break
        endif
      endif
    else
      let s:last_file_id += offset
    endif
    if start_id == s:last_file_id
      break
    endif
    let file_opened = spear#open_file(s:last_file_id+1, 0, 0)
  endwhile
  if file_opened
    echo 'Moved to file #'. (s:last_file_id+1) .' of Spear List'
  else
    echohl WarningMsg | echo 'Error: Cannot find file to open.' | echohl None
    let s:last_file_id = start_id
  endif
endfun

fun! spear#open_menu()
  let s:last_win = winnr()
  let spear_id = bufwinnr(s:spear_buf_name)

  if spear_id == -1
    " create the Spear List buffer and window
    let is_open_id = index(s:spear_lines, expand('%'))
    exec 'keepalt botright '. s:spear_win_height .'split '. s:spear_buf_name
    exec 'silent! read '. s:get_list_file()
    1delete _
    if is_open_id == -1
      normal! gg
    else
      exec 'normal! '.(is_open_id+1).'G'
    endif
    setlocal filetype=spear
    setlocal buftype=acwrite bufhidden=wipe
    setlocal number norelativenumber
    call s:create_menu_maps()
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
            \ |   call spear#save()
            \ | endif
      au BufWriteCmd <buffer>
            \   call spear#save(1)
            \ | if g:spear_quit_on_save
            \ |   call spear#close_menu()
            \ | endif
    augroup END
    let s:spear_is_open = 1
  endif
endfun

fun! spear#close_menu()
  let spear_id = bufwinnr(s:spear_buf_name)
  if winbufnr(s:last_win) != -1
    exec s:last_win .'wincmd w'
  endif
  exec spear_id .'wincmd c'
  let s:spear_is_open = 0
endfun

fun! spear#toggle_menu()
  let spear_id = bufwinnr(s:spear_buf_name)
  if spear_id == -1
    call spear#open_menu()
  else
    call spear#close_menu()
  endif
endfun

" vim: sw=2 fdm=indent
