"============================================================================
"File:        syntastic.vim
"Description: vim plugin for on the fly syntax checking
"Maintainer:  Martin Grenfell <martin.grenfell at gmail dot com>
"Rewrite:     Marc Weber <marco-oweber@gmx.de>
"Version:     2.0
"Last Change: 14 Jul
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================

" this file contains the declarations of the checkers
" complicated implementations should be moved into autoload/syntastic.vim (eg
" see syntastic#HTML)

" If you don't like the default behavior you can use
" g:syntastic['post_process'] function to patch the dictionary.

" create local alias of global var
" vam#DefineAndBind('s:l','g:syntastic','{}')
if !exists('g:syntastic') | let g:syntastic = {} | endif | let s:c = g:syntastic

" the file_types dict is a list of registered checkers.
" A checker is a dictionary describing
" - when to apply the checker
" - how checking takes place
" because its a dicts you can easily overwrite any key
let s:c['file_types'] = get(s:c, 'file_types', {})
" l/c corresponds to "current list of errors" or location list
let s:c['list_type'] = get(s:c, 'list_type', 'l')

let s:c['auto_setup'] = get(s:c, 'auto_setup', 1)

" alias, don't repeat yourself
let tmp = {}

" dsecription:
"  applies: does checker apply to current buffer? Vim expression returns bool

" cmd:
"   if string: shell command. % is replaced by current file
"   if function: will be called with dict.
" prerequisites: conditions which must be met so that this checker can be
"                executed successfully. Must be Vim expression returning bool

" PHP
let tmp['php'] = {
     \   'applies' : '&ft == "php"'
     \ , 'check': {'cmd': 'php -l %', 'efm': '%-GNo syntax errors detected in%.%#,PHP Parse error: %#syntax %trror\, %m in %f on line %l,PHP Fatal %trror: %m in %f on line %l,%-GErrors parsing %.%#,%-G\s%#,Parse error: %#syntax %trror\, %m in %f on line %l,Fatal %trror: %m in %f on line %l' }
     \ }

" HTML
let tmp['html'] = {
    \   'applies' : '&ft == "html"'
    \ , 'check' : function('syntastic#HTML')
    \ , 'prerequisites': 'executable("tidy") && executable("grep")'
    \ , 'tidy_opts' : {
        \'utf-8'       : '-utf8',
        \'ascii'       : '-ascii',
        \'latin1'      : '-latin1',
        \'iso-2022-jp' : '-iso-2022',
        \'cp1252'      : '-win1252',
        \'macroman'    : '-mac',
        \'utf-16le'    : '-utf16le',
        \'utf-16'      : '-utf16',
        \'big5'        : '-big5',
        \'sjis'        : '-shiftjis',
        \'cp850'       : '-ibm858',
        \}
    \ }


" xml / xhtml
" for speed reasons you really want to get
" http://www.w3.org/TR/xhtml1/xhtml1.tgz and make XML_CATALOG_FILES point to
" its catalog.xml file! (There are more ways to tell xmllinte about the
" location of dtd's. That's the most convenient way. The reason is that the
" servers hosting the dtd files had to server too many clients (eg libraries
" used by web apps) refetching the dts on each run - which made them collapse.
let tmp['xml'] = {
    \   'applies' : '&ft =~ "xhtml\\|xml"'
    \ , 'check' : {'cmd': 'xmllint --valid --loaddtd --noout --load-trace %', 'efm': ""}
    \ , 'prerequisites': 'executable("xmllint")'
    \ }

" JS
" contributed by Martin Grenfell & Matthew Kitt's javascript.vim
" TODO: merge and keep one only?

" prio 1 because it does not require configuration ?
let tmp['js_jshint'] = {
    \   'applies' : '&ft == "js"'
    \ , 'check' : { 'cmd': 'jshint %', 'efm' : '%f: line %l\, col %c\, %m,%-G%.%#' }
    \ , 'prerequisites': 'executable("jshint")'
    \ , 'prio': 1
    \ }

let tmp['js_jsl'] = {
    \   'applies' : '&ft == "js"'
    \ , 'check' : function('syntastic#JS_JSL')
    \ , 'prerequisites': 'executable("jsl")'
    \ , 'prio': 1
    \ }


"by  Martin Grenfell <martin.grenfell at gmail dot com>
" we cannot set RUBYOPT on windows like that
" Marc: Why does it hurt having it set?
let s:c['ruby_check'] = get(s:c, 'ruby_check', has('win32') || has('win64') ?  'ruby -W1 -T1 -c %' : 'RUBYOPT= ruby -W1 -c %')
let tmp['ruby'] = {
    \   'applies' : '&ft == "rb"'
    \ , 'check' : {'cmd': s:c.ruby_check, 'efm':  '%-GSyntax OK,%E%f:%l: syntax error\, %m,%Z%p^,%W%f:%l: warning: %m,%Z%p^,%W%f:%l: %m,%-C%.%#' }
    \ , 'prerequisites': 'executable("csslint")'
    \ }

let tmp['eruby'] = {
    \   'applies' : '&ft == "eruby"'
    \ , 'check' : function('syntastic#Eruby')
    \ , 'prerequisites': 'executable("cat") && executabel("sed") && executable("ruby")'
    \ }

let tmp['haml'] = {
    \   'applies' : '&ft == "haml"'
    \ , 'check' : function('syntastic#Haml')
    \ , 'prerequisites': 'executable("haml")'
    \ }

"by  Martin Grenfell <martin.grenfell at gmail dot com>
let tmp['sass'] = {
    \   'applies' : '&ft == "sass"'
    \ , 'check' : function('syntastic#Sass')
    \ , 'prerequisites': 'executable("haml")'
    \ }


let tmp['coffee'] = {
    \   'applies' : '&ft == "coffee"'
    \ , 'check' : {'cmd': 'coffee -c -l -o /tmp %', 'efm': '%EError: In %f\, Parse error on line %l: %m,%EError: In %f\, %m on line %l,%W%f(%l): lint warning: %m,%-Z%p^,%W%f(%l): warning: %m,%-Z%p^,%E%f(%l): SyntaxError: %m,%-Z%p^,%-G' }
    \ , 'prerequisites': 'executable("coffee")'
    \ }

let s:c['perl_efm_program'] = get(s:c,'perl_efm_program', $VIMRUNTIME.'/tools/efm_perl.pl -c')
let tmp['perl'] = {
    \   'applies' : '&ft == "perl"'
    \ , 'check' : {'cmd': s:c['perl_efm_program'].' %', 'efm': '%f:%l:%m' }
    \ , 'prerequisites': 'executable("perl")'
    \ }

" Sam Nguyen <samxnguyen@gmail.com>
let tmp['go'] = {
    \   'applies' : '&ft == "go"'
    \ , 'check' : {'cmd': '6g -o /dev/null %', 'efm':  '%E%f:%l: %m'}
    \ , 'prerequisites': 'executable("6g")'
    \ }

" by Ory Band <oryband at gmail dot com>
let tmp['css'] = {
    \   'applies' : '&ft == "css"'
    \ , 'check' : {'cmd': 'csslint %', 'efm':  '%+Gcsslint:\ There%.%#,%A%f:,%C%n:\ %t%\\w%\\+\ at\ line\ %l\,\ col\ %c,%Z%m\ at\ line%.%#,%A%>%f:,%C%n:\ %t%\\w%\\+\ at\ line\ %l\,\ col\ %c,%Z%m,%-G%.%#' }
    \ , 'prerequisites': 'executable("csslint")'
    \ }

"by  Martin Grenfell <martin.grenfell at gmail dot com>
let tmp['cucumber'] = {
    \   'applies' : '&ft == "cucumber"'
    \ , 'check' : {'cmd': 'cucumber --dry-run --quiet --strict --format pretty %', 'efm':  '%f:%l:%c:%m,%W      %.%# (%m),%-Z%f:%l:%.%#,%-G%.%#' }
    \ , 'prerequisites': 'executable("cucumber")'
    \ }

"by      Hannes Schulz <schulz at ais dot uni-bonn dot de>
" shouldn't the default just be nvcc?
let s:c['nvcc'] = get(s:c,'nvcc', '/usr/loca/cuda/bin/nvcc')
let tmp['cudo'] = {
    \   'applies' : '&ft == "cuda"'
    \ , 'check' : function('syntastic#CUDA')
    \ , 'prerequisites': 'executable(g:syntastic.nvcc)'
    \ }

"by Julien Blanchard <julien at sideburns dot eu>
let tmp['less'] = {
    \   'applies' : '&ft == "less"'
    \ , 'check' : {'cmd': 'lessc % /dev/null', 'efm':  'Syntax %trror on line %l,! Syntax %trror: on line %l: %m,%-G%.%#' }
    \ , 'prerequisites': 'executable("lessc")'
    \ }

"by  Gregor Uhlenheuer <kongo2002 at gmail dot com>
let tmp['lua'] = {
    \   'applies' : '&ft == "lua"'
    \ , 'check' : {'cmd': 'luac -p %', 'efm':  'luac: %#%f:%l: %m' }
    \ , 'prerequisites': 'executable("luac")'
    \ }


"by  Martin Grenfell <martin.grenfell at gmail dot com>
let tmp['docbk'] = {
    \   'applies' : '&ft == "css"'
    \ , 'check' : {'cmd': 'xmllint --xinclude --noout --postvalid %', 'efm':  '%E%f:%l: parser error : %m,%W%f:%l: parser warning : %m,%E%f:%l:%.%# validity error : %m,%W%f:%l:%.%# validity warning : %m,%-Z%p^,%-C%.%#,%-G%.%#' }
    \ , 'prerequisites': 'executable("xmllint")'
    \ }

"by  Jason Graham <jason at the-graham dot com>
let tmp['matlab'] = {
    \   'applies' : '&ft == "ml"'
    \ , 'check' : {'cmd': 'mlint -id $* %', 'efm':  'L %l (C %c): %*[a-zA-Z0-9]: %m,L %l (C %c-%*[0-9]): %*[a-zA-Z0-9]: %m' }
    \ , 'prerequisites': 'executable("mlint")'
    \ }

"by  Eivind Uggedal <eivind at uggedal dot com>
let tmp['puppet'] = {
    \   'applies' : '&ft == "css"'
    \ , 'check' : {'cmd': 'puppet --color=false --parseonly %', 'efm':  'err: Could not parse for environment %*[a-z]: %m at %f:%l' }
    \ , 'prerequisites': 'executable("puppet")'
    \ }

" TODO:, function('syntastic#SyntaxCheckers_python_Term')
let tmp['python'] = {
    \   'applies' : '&ft == "python"'
    \ , 'check' : {'cmd': 'pyflakes %', 'efm':  '%E%f:%l: could not compile,%-Z%p^,%W%f:%l: %m,%-G%.%#' }
    \ , 'prerequisites': 'executable("pyflakes")'
    \ }

let tmp['python_simple'] = {
      \  'applies' : '&ft == "python"'
      \ , 'check' : function('syntastic#PythonSimple')
      \ , 'prerequisites': 'has("python")'
      \ }

" by  Martin Grenfell <martin.grenfell at gmail dot com>
let tmp['latex'] = {
    \   'applies' : '&ft == "latex"'
    \ , 'check' : {'cmd': 'lacheck %', 'efm':  '%-G** %f:,%E"%f"\, line %l: %m' }
    \ , 'prerequisites': 'executable("lacheck")'
    \ }

" let tmp['xhttm'] =  join with html? TODO

function! SyntaxCheckers_tex_GetLocList()
    let makeprg = 'lacheck '.shellescape(expand('%'))
    let errorformat =  '%-G** %f:,%E"%f"\, line %l: %m'
    return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endfunction

"by Eric Thomas <eric.l.m.thomas at gmail dot com>
" does this do a syntax check only ? No, it runs the code!
" Thus this should go into vim-addon-actions
"let tmp['tclsh'] = {
"    \   'applies' : '&ft == "tcl"'
"    \ , 'check' : {'cmd': 'ctlsh %', 'efm':  '%f:%l:%m' }
"    \ , 'prerequisites': 'executable("csslint")'
"    \ }

" haskell, hs, ghc; use vim-addon-actions which provides background
" compilation process, or try scion
" this feature will no longer be provided by syntastic

" C: the old implemention contained many os and library specific code.
" Its ok to add it. But I don't think it should be default.
" For now I recommend using make (which is usually fast anyway?) and
" vim-addon-actions ..

" scala: get github.com/MarcWeber/ensime or use a full blown IDE :(


" merge configuration settings keeping user's predefined keys:
call extend(s:c['file_types'], tmp, 'keep')
unlet tmp

if has_key(s:c, 'post_process')
  " allow user to drop keys or overwrite defaults ..
  call s:c.post_process()
endif

" find checkers which are cabable of checking the current buffer
fun! SyntasticOptions(drop_prerequisites_missmatch)
  let r = {}
  for [name, dict] in items(s:c['file_types'])
    if type(dict) != type({}) | continue | endif
    exec 'let A = '. get(dict,'applies',1) .' && (!a:drop_prerequisites_missmatch || '. get(dict,'prerequisites','1').')'
    if A
      let r[name] = dict
    endif
    unlet name dict
  endfor
  return r
endf

fun! SyntasticCheckSimple(cmd, efm, list_type)
  " echo "syntastic, checking .."
  exec 'let efm="'. escape(a:efm, '"').'"'
  " don't use make. scrolling lines are annoying!
  let g:syntastic.last_cmd = a:cmd
  call system(a:cmd.' &>'.s:c.tmpfile)
  silent! exec a:list_type.'file '.s:c.tmpfile
endf

" do the check
fun! SyntasticCheck()
  if !exists('b:syntastic_checker')
    echoe 'b:syntastic_checker is not set. Use call SyntasticSetupBufWriteChecker(1 or 0) to do so'
    return
  endif
  if b:syntastic_checker == "" | return | endif
  let d = s:c.file_types[b:syntastic_checker]
  let list_type = get(d, 'list_type', s:c.list_type)
  let e=&efm
  if !exists('s:c.tmpfile') | let s:c.tmpfile = tempname() | endif
  
  if type(d.check) == type({}) && has_key(d.check, 'cmd') && has_key(d.check, 'efm')

    " (1) make like checker
    call SyntasticCheckSimple(substitute(d.check.cmd,'%',shellescape(expand('%')),'%'), d.check.efm, list_type)

  elseif type(d.check) == 2

    " (2) funcref must fill location /error list
    call call(d.check, [list_type], d)

  endif

  let any = 0
  for l in list_type == 'c' ? getqflist() : getloclist(bufwinnr('%'))
    if get(l, 'lnum', 0) != 0 | let any =1 | break | endif
  endfor
  " colse open loc/ error list if there are errors / no errors
  exec list_type.(any ? 'open' : 'close')

  exec 'let efm="'.escape(e, '"').'"'
endf

fun! SyntasticSetupBufWriteChecker(setup_au)
  " try to find a matching checker
  let b:syntastic_checker = tlib#input#List('s', 'Syntastic filetype checker:', keys(SyntasticOptions(1)))
  if b:syntastic_checker == "" | return 0 | endif
  augroup SyntasticCheck
    au!
    if a:setup_au
      au BufWritePost <buffer> call SyntasticCheck()
    endif
  augroup end
  return 1
endf

if s:c.auto_setup
  augroup SyntasticSetup
    autocmd BufRead,BufNewFile * call SyntasticSetupBufWriteChecker(1)
  augroup end
endif

command SyntasticDebug   echo "List of checkers which think that they are capabale of checking the current buffer:" |
                       \ echo "[] denotes none (epmty list)" |
                       \ echo "matching checkers: " . string(keys(SyntasticOptions(0))) |
                       \ echo "matching checkers and prerequisites met: ".string(keys(SyntasticOptions(1)))

command SyntasticDontCheckThisBuf silent! unlet b:syntastic_checker
command SyntasticSetupBufWriteCheckerThisBuf call SyntasticSetupBufWriteChecker(1)
