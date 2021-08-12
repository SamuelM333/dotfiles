"" Plugins
Plug 'hashivim/vim-terraform'
Plug 'tomasiser/vim-code-dark'
Plug 'yasuhiroki/circleci.vim'

"" DTree configuration
let g:NERDTreeChDirMode=2
let g:NERDTreeIgnore=['\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:nerdtree_tabs_focus_on_files=1
"let NERDTreeMapOpenInTab='<ENTER>'
let NERDTreeMapOpenInTabSilent='<TAB>'
let g:NERDTreeWinSize = 50
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite
nnoremap <silent> <F2> :NERDTreeFind<CR>
noremap <F3> :NERDTreeToggle<CR>
nmap <C-N><C-N> :set invnumber<CR> :set relativenumber!<CR>

"" set shortcut for open Nerdtree
"nmap " :NERDTreeToggle<CR>

"" Make Nerdtree show .files by default
let NERDTreeShowHidden=1

"" Color scheme
" colorscheme codedark

let fancy_symbols_enabled = 1

"" Terraform
let g:terraform_align=1
let g:terraform_fmt_on_save=1

"" CircleCI
let g:circleci_omnifunc_enable=1

"" Indentation
set ts=4 sw=4
nnoremap <Tab> >>_
nnoremap <S-Tab> <<_
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv|

autocmd BufNewFile,BufRead *.rego set syntax=go
