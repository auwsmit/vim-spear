Basically recreating Primeagen's Harpoon 2 nvim plugin from scratch, but in
vimscript. It functions almost identically to Harpoon 2. Still a work in
progress.

If you wanna try it out, then install via your preferred plugin
manager and put mappings like these somewhere in your vim config file(s):

    " all neatly around home row
    nnoremap <Leader>A :SpearAdd<cr>
    nnoremap <Leader>X :SpearDelete<cr>
    nnoremap <C-m>    :SpearToggle<cr>
    nnoremap <C-h>    :SpearOpen 1<cr>
    nnoremap <C-j>    :SpearOpen 2<cr>
    nnoremap <C-k>    :SpearOpen 3<cr>
    nnoremap <C-l>    :SpearOpen 4<cr>
    " < previous, and > next in the list
    nnoremap <C-.>    :SpearNext<cr>
    nnoremap <C-,>    :SpearPrev<cr>

and there are even some optional variables to adjust based on your preferences:

(these are the defaults)

    " prompt to delete invalid files
    let g:spear_delete_blank_lines = 0
    let g:spear_delete_invalid_files = 0

    " close the menu whenever it's manually saved
    let g:spear_quit_on_save = 0

    " always save when the list menu changes
    let g:spear_quit_on_change = 0

    " cycle with the previous/next maps
    let g:spear_prev_next_cycle = 0

    " convert backslashes to forward slashes
    " (purely aesthetic, shouldn't affect behavior)
    let g:spear_convert_backslashes = 1
