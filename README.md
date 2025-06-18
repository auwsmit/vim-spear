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

