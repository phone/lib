set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'
call vundle#end()
filetype plugin indent on
set hidden
set ai
set ic
set copyindent
set preserveindent
syntax on

runtime ftplugin/man.vim

nnoremap <Leader>c :YcmCompleter GoToDeclaration<CR>
nnoremap <Leader>C :YcmCompleter GoToDefinition<CR>
nnoremap <Leader>R :YcmCompleter GoToReferences<CR>
nnoremap <Leader>T :YcmCompleter GetType<CR>
nnoremap <Leader>D :YcmCompleter GetDoc<CR>
nnoremap <Leader>P :YcmCompleter GetParent<CR>

nnoremap <Leader>fc mp:%!clang-format<CR>'p
nnoremap <Leader>fg mp:%!gofmt<CR>'p
nnoremap <Leader>ff mp:%!fmt<CR>'p

function TwoSpaces()
    set ts=2
    set sw=2
    set softtabstop=2
    set et
endfunction

function FourSpaces()
    set ts=4
    set sw=4
    set softtabstop=4
    set et
endfunction

function EightSpaces()
    set ts=8
    set sw=8
    set softtabstop=8
    set et
endfunction
