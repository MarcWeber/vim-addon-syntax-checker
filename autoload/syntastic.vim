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

let s:plugin_root = expand('<sfile>:h:h')

" put this all into a function you can call to force a setup
" This may be required if you want to patch the dict
let s:did_setup = 0
fun! syntastic#Setup()
  " do this once only:
  if s:did_setup | return | endif
  let s:did_setup = 1

" this file contains the declarations of the checkers
" complicated implementations should be moved into autoload/syntastic.vim (eg
" see syntastic_checkers#HTML)

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
let s:c.tmpfile = tempname()

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
     \ , 'prerequisites': 'executable("php")'
     \ }

" HTML
let tmp['html'] = {
    \   'applies' : '&ft == "html"'
    \ , 'check' : funcref#Function('syntastic_checkers#HTML')
    \ , 'prerequisites': 'executable("tidy") && executable("grep")'
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
    \ , 'check' : {'cmd': 'xmllint --valid --loaddtd --noout --load-trace %', 'efm': "%f:%l:%m"}
    \ , 'prerequisites': 'executable("xmllint")'
    \ }

" JS
" contributed by Martin Grenfell & Matthew Kitt's javascript.vim
" TODO: merge and keep one only?

" prio 1 because it does not require configuration ?
" TODO test
let tmp['js_jshint'] = {
    \   'applies' : '&ft == "javascript"'
    \ , 'check' : { 'cmd': 'jshint %', 'efm' : '%f: line %l\, col %c\, %m,%-G%.%#' }
    \ , 'prerequisites': 'executable("jshint")'
    \ , 'prio': 1
    \ }

" TODO test
let tmp['js_jsl'] = {
    \   'applies' : '&ft == "javascript"'
    \ , 'check' : funcref#Function('syntastic_checkers#JS_JSL')
    \ , 'prerequisites': 'executable("jsl")'
    \ , 'prio': 1
    \ }

" jslint: 
" " good enough:
" set efm=%+P%f,%mLine\ %l\\,\ Pos\ %c,%C%m
" perfect:
" set efm=%+P%f,%Z%sLine\ %l\\,\ Pos\ %c,%E%m


" spidermonkey: {foo:3,} is fine according to this check, but IE yells about
" this. So take care!
let tmp['js'] = {
    \   'applies' : '&ft == "javascript" && expand("%:e") != "json"'
    \ , 'check' : {'cmd': 'js -C %', 'efm':  '%E%f:%l:\ %m,%-C:%l:\ %s,%Z%s:%p'}
    \ , 'prerequisites': 'executable("js")'
    \ , 'prio': 1
    \ }


let tmp['js'] = {
    \   'applies' : '&ft == "javascript" && expand("%:e") != "json"'
    \ , 'check' : {'cmd': 'js -C %', 'efm':  '%E%f:%l:\ %m,%-C:%l:\ %s,%Z%s:%p'}
    \ , 'prerequisites': 'executable("js")'
    \ , 'prio': 1
    \ }


let tmp['js_json_by_php'] = {
    \   'applies' : '&ft == "javascript" && expand("%:e") == "json"'
    \ , 'check' : {'cmd': 'php -f '.s:plugin_root.'/tools/json_checker.php  %', 'efm':  '%f:%l: %m'}
    \ , 'prerequisites': 'executable("php")'
    \ , 'prio': 1
    \ }

let tmp['js_json_by_python'] = {
    \   'applies' : '&ft == "javascript" && expand("%:e") == "json"'
    \ , 'check' : {'cmd': 'php -f '.s:plugin_root.'/tools/json_checker.py  %', 'efm':  '%f:%l: %m'}
    \ , 'prerequisites': 'executable("python")'
    \ , 'prio': 2
    \ }

" inaccurate: accepts ', but " must be used
let tmp['js_json'] = {
    \   'applies' : '&ft == "javascript" && expand("%:e") == "json"'
    \ , 'check' : {'cmd': '{ echo -n "var x= "; cat %; } | js 2>&1 | sed -e "s/^\\([0-9]\+\\):/"%":\\1:/"', 'efm':  '%f:%l:\ %m,%-C:%l:\ %s,%Z%s:%p'}
    \ , 'prerequisites': 'executable("js")'
    \ , 'prio': 3
    \ }

"by  Martin Grenfell <martin.grenfell at gmail dot com>
" we cannot set RUBYOPT on windows like that
" Marc: Why does it hurt having it set?
let s:c['ruby_check'] = get(s:c, 'ruby_check', has('win32') || has('win64') ?  'ruby -W1 -T1 -c %' : 'RUBYOPT= ruby -W1 -c %')
let tmp['ruby'] = {
    \   'applies' : '&ft == "ruby"'
    \ , 'check' : {'cmd': s:c.ruby_check, 'efm':  '%-GSyntax OK,%E%f:%l: syntax error\, %m,%Z%p^,%W%f:%l: warning: %m,%Z%p^,%W%f:%l: %m,%-C%.%#' }
    \ , 'prerequisites': 'executable("ruby")'
    \ }

" TODO (test)
let tmp['eruby'] = {
    \   'applies' : '&ft == "eruby"'
    \ , 'check' : funcref#Function('syntastic_checkers#Eruby')
    \ , 'prerequisites': 'executable("cat") && executable("sed") && executable("ruby")'
    \ }

let tmp['haml'] = {
    \   'applies' : '&ft == "haml"'
    \ , 'check' : funcref#Function('syntastic_checkers#Haml')
    \ , 'prerequisites': 'executable("haml")'
    \ }

"by  Martin Grenfell <martin.grenfell at gmail dot com>
" TODO (test). Probably this can be done like HAML
" \ , 'check' : funcref#Function('syntastic_checkers#Sass')
let tmp['sass'] = {
    \   'applies' : '&ft == "sass"'
    \ , 'check' : {'cmd' : 'sass %', 'efm': '%ESyntax %trror:%m,%C        on line %l of %f,%Z%m,%Wwarning on line %l:,%Z%m,Syntax %trror on line %l: %m'}
    \ , 'prerequisites': 'executable("haml")'
    \ }


"TODO (test)
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
"TODO (test)
let tmp['go'] = {
    \   'applies' : '&ft == "go"'
    \ , 'check' : {'cmd': '6g -o /dev/null %', 'efm':  '%E%f:%l: %m'}
    \ , 'prerequisites': 'executable("6g")'
    \ }

" by Ory Band <oryband at gmail dot com>
"TODO (test)
let tmp['css'] = {
    \   'applies' : '&ft == "css"'
    \ , 'check' : {'cmd': 'csslint %', 'efm':  '%+Gcsslint:\ There%.%#,%A%f:,%C%n:\ %t%\\w%\\+\ at\ line\ %l\,\ col\ %c,%Z%m\ at\ line%.%#,%A%>%f:,%C%n:\ %t%\\w%\\+\ at\ line\ %l\,\ col\ %c,%Z%m,%-G%.%#' }
    \ , 'prerequisites': 'executable("csslint")'
    \ }

"by  Martin Grenfell <martin.grenfell at gmail dot com>
"TODO (test)
let tmp['cucumber'] = {
    \   'applies' : '&ft == "cucumber"'
    \ , 'check' : {'cmd': 'cucumber --dry-run --quiet --strict --format pretty %', 'efm':  '%f:%l:%c:%m,%W      %.%# (%m),%-Z%f:%l:%.%#,%-G%.%#' }
    \ , 'prerequisites': 'executable("cucumber")'
    \ }

"by      Hannes Schulz <schulz at ais dot uni-bonn dot de>
" shouldn't the default just be nvcc?
"TODO (test)
let s:c['nvcc'] = get(s:c,'nvcc', '/usr/loca/cuda/bin/nvcc')
let tmp['cudo'] = {
    \   'applies' : '&ft == "cuda"'
    \ , 'check' : funcref#Function('syntastic_checkers#CUDA')
    \ , 'prerequisites': 'executable(g:syntastic.nvcc)'
    \ }

"by Julien Blanchard <julien at sideburns dot eu>
"TODO (test)
let tmp['less'] = {
    \   'applies' : '&ft == "less"'
    \ , 'check' : {'cmd': 'lessc % /dev/null', 'efm':  'Syntax %trror on line %l,! Syntax %trror: on line %l: %m,%-G%.%#' }
    \ , 'prerequisites': 'executable("lessc")'
    \ }

"by  Gregor Uhlenheuer <kongo2002 at gmail dot com>
"TODO (test)
let tmp['lua'] = {
    \   'applies' : '&ft == "lua"'
    \ , 'check' : {'cmd': 'luac -p %', 'efm':  'luac: %#%f:%l: %m' }
    \ , 'prerequisites': 'executable("luac")'
    \ }


"by  Martin Grenfell <martin.grenfell at gmail dot com>
"TODO (test)
let tmp['docbk'] = {
    \   'applies' : '&ft == "docbk"'
    \ , 'check' : {'cmd': 'xmllint --xinclude --noout --postvalid %', 'efm':  '%E%f:%l: parser error : %m,%W%f:%l: parser warning : %m,%E%f:%l:%.%# validity error : %m,%W%f:%l:%.%# validity warning : %m,%-Z%p^,%-C%.%#,%-G%.%#' }
    \ , 'prerequisites': 'executable("xmllint")'
    \ }

"by  Jason Graham <jason at the-graham dot com>
"TODO (test)
let tmp['matlab'] = {
    \   'applies' : '&ft == "ml"'
    \ , 'check' : {'cmd': 'mlint -id $* %', 'efm':  'L %l (C %c): %*[a-zA-Z0-9]: %m,L %l (C %c-%*[0-9]): %*[a-zA-Z0-9]: %m' }
    \ , 'prerequisites': 'executable("mlint")'
    \ }

"by  Eivind Uggedal <eivind at uggedal dot com>
"TODO (test)
let tmp['puppet'] = {
    \   'applies' : '&ft == "css"'
    \ , 'check' : {'cmd': 'puppet --color=false --parseonly %', 'efm':  'err: Could not parse for environment %*[a-z]: %m at %f:%l' }
    \ , 'prerequisites': 'executable("puppet")'
    \ }

" TODO:, function('syntastic_checkers#SyntaxCheckers_python_Term')
"TODO (test)
let tmp['python'] = {
    \   'applies' : '&ft == "python"'
    \ , 'check' : {'cmd': 'pyflakes %', 'efm':  '%E%f:%l: could not compile,%-Z%p^,%W%f:%l: %m,%-G%.%#' }
    \ , 'prerequisites': 'executable("pyflakes")'
    \ }

let tmp['python_simple'] = {
      \  'applies' : '&ft == "python"'
      \ , 'check' : funcref#Function('syntastic_checkers#PythonSimple')
      \ , 'prerequisites': 'has("python")'
      \ }

" by  Martin Grenfell <martin.grenfell at gmail dot com>
"TODO (test)
" , 'check' : {'cmd': 'lacheck %', 'efm':  '%-G** %f:,%E"%f"\, line %l: %m' }
" the  syntastic_checkers#LATEX let's you drop lines you don't care about
" easily by setting the 'ignore_regex' key
let tmp['latex'] = {
    \   'applies' : '&ft == "plaintex"'
    \ , 'check' : funcref#Function('syntastic_checkers#LATEX')
    \ , 'prerequisites': 'executable("lacheck")'
    \ , 'ignore_regex': ''
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

if s:c.auto_setup
  augroup SyntasticSetup
    autocmd BufRead,BufNewFile * call syntastic#SetupBufWriteChecker(1)
    autocmd BufWritePost * call syntastic#Check()
  augroup end
endif

command! SyntaxCheckerDebug   echo "List of checkers which think that they are capabale of checking the current buffer:" |
                       \ echo "[] denotes none (epmty list)" |
                       \ echo "matching checkers: " . string(keys(syntastic#Options(0))) |
                       \ echo "matching checkers and prerequisites met: ".string(keys(syntastic#Options(1)))

command! SyntaxCheckerDontCheckThisBuf silent! unlet b:syntastic_checker
command! SetupBufWriteCheckerThisBuf call syntastic#SetupBufWriteChecker(1)
command! SyntaxCheckerCheckBuf call syntastic#Check()

endf


" find checkers which are cabable of checking the current buffer
fun! syntastic#Options(drop_prerequisites_missmatch)
  " TODO support prio?
  let r = {}
  for [name, dict] in items(s:c['file_types'])
    if type(dict) != type({}) | unlet name dict | continue | endif
    exec 'let A = '. get(dict,'applies',1) .' && (!a:drop_prerequisites_missmatch || '. get(dict,'prerequisites','1').')'
    if A
      let r[name] = dict
    endif
    unlet name dict
  endfor
  return r
endf

fun! syntastic#CheckSimple(cmd, efm, list_type)
  " echo "syntastic, checking .."
  exec 'set efm='. escape(a:efm, ' \,|"')
  " don't use make. scrolling lines are annoying!
  let g:syntastic.last_cmd = a:cmd
  if a:cmd != ""
    call system(a:cmd.' &>'.s:c.tmpfile)
  endif
  silent! exec a:list_type.'file '.s:c.tmpfile
endf

" do the check
fun! syntastic#Check()
  if !exists('b:syntastic_checker')
    return
  endif
  if b:syntastic_checker == "" | return | endif
  let d = s:c.file_types[b:syntastic_checker]
  let list_type = get(d, 'list_type', s:c.list_type)
  let e=&efm
  if type(d.check) == type({}) && has_key(d.check, 'cmd') && has_key(d.check, 'efm')

    " (1) make like checker
    call syntastic#CheckSimple(substitute(d.check.cmd,'%',shellescape(expand('%')),'g'), d.check.efm, list_type)

  elseif type(d.check) == 2 || type(d.check) == 4 && has_key(d.check, 'faked_function_reference')

    " (2) funcref must fill location /error list
    call funcref#Call(d.check, [list_type], d)

  endif

  let any = 0
  for l in list_type == 'c' ? getqflist() : getloclist(bufwinnr('%'))
    if get(l, 'lnum', 0) != 0 | let any =1 | break | endif
  endfor
  " colse open loc/ error list if there are errors / no errors
  exec list_type.(any ? 'open' : 'close')

  exec 'set efm='.escape(e, "\t".' \,|"')
endf


fun! syntastic#ComparePrio(i1, i2)
  return get(a:i1.v, 'prio', 1) - get(a:i2.v, 'prio', 1)
endf

fun! syntastic#SetupBufWriteChecker(setup_au)
  " try to find a matching checker
  let applicants = values(map(syntastic#Options(1), "{'k': v:key, 'v': v:val}"))
  call sort(applicants,  'syntastic#ComparePrio')

  if len(applicants) == 0
    let b:syntastic_checker = ""
    return 0
  endif

  if len(applicants) == 1
    let b:syntastic_checker == applicants[0].k
    return 1
  endif

  let x = filter(copy(applicants), 'get(v:val.v, "prio") == '.string(get(applicants[0].v, 'prio')))
  let keys = map(copy(x), 'v:val.k')
  let b:syntastic_checker = tlib#input#List('s', 'Syntastic filetype checker:', keys)

  return b:syntastic_checker == "" ? 0 : 1
endf
