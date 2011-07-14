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
let s:cfg['file_types'] = get(s:c, 'file_types', {})

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
     \ , 'cmd' : 'php -l %'
     \ }

" HTML
let tmp['html'] = {
    \   'applies' : '&ft == "html"'
    \ , 'check' : function('syntastic#HTML')
    \ , 'prerequisites': 'executable("tidy") && executable("grep")'
    \ , 'tidy_opts' = {
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
        \},
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
    \ , 'cmd' : function('syntastic#JS_JSL')
    \ , 'prerequisites': 'executable("jsl")'
    \ , 'prio': 1
    \ }

let tmp['eruby'] = {
    \   'applies' : '&ft == "eruby"'
    \ , 'cmd' : function('syntastic#Eruby')
    \ , 'prerequisites': 'executable("cat") && executabel("sed") && executable("ruby")'
    \ }

let tmp['haml'] = {
    \   'applies' : '&ft == "haml"'
    \ , 'cmd' : function('syntastic#Haml')
    \ , 'prerequisites': 'executable("haml")'
    \ }

let tmp['coffee'] = {
    \   'applies' : '&ft == "coffee"'
    \ , 'cmd' : {'cmd': 'coffee -c -l -o /tmp %', 'efm': '%EError: In %f\, Parse error on line %l: %m,%EError: In %f\, %m on line %l,%W%f(%l): lint warning: %m,%-Z%p^,%W%f(%l): warning: %m,%-Z%p^,%E%f(%l): SyntaxError: %m,%-Z%p^,%-G' }
    \ , 'prerequisites': 'executable("coffee")'
    \ }

let s:cfg['perl_efm_program'] = get(s:cfg,'perl_efm_program', $VIMRUNTIME.'/tools/efm_perl.pl -c')
let tmp['perl'] = {
    \   'applies' : '&ft == "perl"'
    \ , 'cmd' : {'cmd': s:cfg['perl_efm_program'].' %', 'efm': '%f:%l:%m' }
    \ , 'prerequisites': 'executable("perl")'
    \ }

" Sam Nguyen <samxnguyen@gmail.com>
let tmp['go'] = {
    \   'applies' : '&ft == "go"'
    \ , 'cmd' : {'cmd': '6g -o /dev/null %', 'efm':  '%E%f:%l: %m'}
    \ , 'prerequisites': 'executable("6g")'
    \ }


" haskell, hs, ghc; use vim-addon-actions which provides background
" compilation process, or try scion
" this feature will no longer be provided by syntastic

" C: the old implemention contained many os and library specific code.
" Its ok to add it. But I don't think it should be default.
" For now I recommend using make (which is usually fast anyway?) and
" vim-addon-actions ..

" scala: get github.com/MarcWeber/ensime or use a full blown IDE :(

"grep out the '<table> lacks "summary" attribute' since it is almost
"always present and almost always useless
let encopt = s:TidyEncOptByFenc()
let makeprg="tidy ".encopt." --new-blocklevel-tags 'section, article, aside, hgroup, header, footer, nav, figure, figcaption' --new-inline-tags 'video, audio, embed, mark, progress, meter, time, ruby, rt, rp, canvas, command, details, datalist' --new-empty-tags 'wbr, keygen' -e ".shellescape(expand('%'))." 2>&1 \\| grep -v '\<table\> lacks \"summary\" attribute' \\| grep -v 'not approved by W3C'"
let errorformat='%Wline %l column %c - Warning: %m,%Eline %l column %c - Error: %m,%-G%.%#,%-G%.%#'
let loclist = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })

"the file name isnt in the output so stick in the buf num manually
for i in loclist
let i['bufnr'] = bufnr("")
endfor


" merge configuration settings keeping user's predefined keys:
call extend(s:cfg['file_types'], tmp, 'keep')
unlet tmp

if has_key(s:cfg, 'post_process')
  " allow user to drop keys or overwrite defaults ..
  call s:cfg.post_process()
endif

