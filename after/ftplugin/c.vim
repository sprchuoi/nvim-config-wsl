set commentstring=//\ %s

" Disable inserting comment leader after hitting o or O or <Enter>
set formatoptions-=o
set formatoptions-=r

nnoremap <silent> <buffer> <F9> :call <SID>compile_run_c()<CR>
command! -buffer -nargs=1 CStd call <SID>set_c_std(<f-args>)

if !exists('g:c_build_std')
  let g:c_build_std = 'c11'
endif

function! s:set_c_std(std) abort
  if a:std =~# '^c\d\+$' || a:std =~# '^gnu\d\+$' || a:std =~# '^c89$' || a:std =~# '^c90$'
    let g:c_build_std = a:std
    echom 'C standard set to ' . g:c_build_std
  else
    echoerr 'Invalid C standard. Example: :CStd c99'
  endif
endfunction

function! s:compile_run_c() abort
  let src_path = expand('%:p:~')
  let src_noext = expand('%:p:~:r')
  " The building flags
  let _flag = '-Wall -Wextra -std=' . g:c_build_std . ' -O2'

  if executable('clang')
    let prog = 'clang'
  elseif executable('gcc')
    let prog = 'gcc'
  else
    echoerr 'No C compiler found on the system!'
  endif
  call s:create_term_buf('h', 20)
  execute printf('term %s %s %s -o %s && %s', prog, _flag, src_path, src_noext, src_noext)
  startinsert
endfunction

function s:create_term_buf(_type, size) abort
  set splitbelow
  set splitright
  if a:_type ==# 'v'
    vnew
  else
    new
  endif
  execute 'resize ' . a:size
endfunction
