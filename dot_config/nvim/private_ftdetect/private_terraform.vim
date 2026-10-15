augroup filetypedetect
    autocmd BufRead,BufNewFile tf set filetype=terraform
    autocmd BufRead,BufNewFile tfvars set filetype=terraform
    autocmd BufRead,BufNewFile tfstate set filetype=json
augroup END
