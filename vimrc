set nocompatible
filetype plugin indent on
set hidden
set ai
set ic
set hls
set is
set copyindent
set preserveindent

runtime ftplugin/man.vim

let mapleader = " "

set tags=./tags,tags;

nnoremap <Leader>f mp:%!clang-format<CR>'p
nnoremap <Leader>l :ls<CR>
nnoremap <Leader>1 :b 1<CR>
nnoremap <Leader>2 :b 2<CR>
nnoremap <Leader>3 :b 3<CR>
nnoremap <Leader>4 :b 4<CR>
nnoremap <Leader>5 :b 5<CR>
nnoremap <Leader>6 :b 6<CR>
nnoremap <Leader>7 :b 7<CR>
nnoremap <Leader>8 :b 8<CR>
nnoremap <Leader>9 :b 9<CR>
nnoremap <Leader>0 :b 10<CR>
nnoremap <Leader><Leader> :b#<CR>

nnoremap <C-b> :CtrlPBuffer<CR>

autocmd FileType cpp set ts=2
autocmd FileType cpp set sw=2
autocmd FileType cpp set et

autocmd FileType c set ts=2
autocmd FileType c set sw=2
autocmd FileType c set et

syntax enable
