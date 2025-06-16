Basically recreating Primeagen's Harpoon 2 nvim plugin from scratch, but in vimscript. Still an early work in progress. If you wanna try it out (it works almost identically to Harpoon 2), then install via your favorite package manager and put mappings like these somewhere in your vim config file(s):

    nnoremap <space>s :SpearToggle<cr>
    nnoremap <space>a :SpearAdd<cr>
    nnoremap <space>x :SpearDelete<cr>
    nnoremap <c-h>    :SpearOpen 1<cr>
    nnoremap <c-j>    :SpearOpen 2<cr>
    nnoremap <c-k>    :SpearOpen 3<cr>
    nnoremap <c-l>    :SpearOpen 4<cr>

