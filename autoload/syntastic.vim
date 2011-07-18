" utils {{{1

function! syntastic#ErrorBalloonExpr()
    if !exists('b:syntastic_balloons') | return '' | endif
    return get(b:syntastic_balloons, v:beval_lnum, '')
endfunction

function! syntastic#HighlightErrors(errors, termfunc)
    call clearmatches()
    for item in a:errors
        if item['col']
            let lastcol = col([item['lnum'], '$'])
            let lcol = min([lastcol, item['col']])
            call matchadd('SpellBad', '\%'.item['lnum'].'l\%'.lcol.'c')
        else
            let group = item['type'] == 'E' ? 'SpellBad' : 'SpellCap'
            let term = a:termfunc(item)
            if len(term) > 0
                call matchadd(group, '\%' . item['lnum'] . 'l' . term)
            endif
        endif
    endfor
endfunction

" checker implementations {{{1

function syntastic#HTML() dict abort
  throw "TODO"
  " return get(tidy_opts, &fileencoding, '-utf8')
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

  return get(tidy_opts, &fileencoding, '-utf8')
  "
endf

function syntastic#JS_JSL()
  throw "TODO"

"    'efm' : '%W%f(%l): lint warning: %m,%-Z%p^,%W%f(%l): warning: %m,%-Z%p^,%E%f(%l): SyntaxError: %m,%-Z%p^,%-G'
  let makeprg = "jsl" . jslconf . " -nologo -nofilelisting -nosummary -nocontext -process ".shellescape(expand('%'))
  let errorformat=''
  return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endfunction

function syntastic#Eruby()
  " TODO get rid of sed etc?
  throw "TODO"
    let makeprg='sed "s/<\%=/<\%/g" '. shellescape(expand("%")) . ' \| RUBYOPT= ruby -e "require \"erb\"; puts ERB.new(ARGF.read, nil, \"-\").src" \| RUBYOPT= ruby -c'
    let errorformat='%-GSyntax OK,%E-:%l: syntax error\, %m,%Z%p^,%W-:%l: warning: %m,%Z%p^,%-C%.%#'
    let loclist = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })

    "the file name isnt in the output so stick in the buf num manually
    for i in loclist
        let i['bufnr'] = bufnr("")
    endfor

    return loclist
function

function syntastic#Haml()
  " extra function required?
  throw "TODO"
  let output = system("haml -c " . shellescape(expand("%")))
  if v:shell_error != 0
    "haml only outputs the first error, so parse it ourselves
    let line = substitute(output, '^\%(Syntax\|Haml\) error on line \(\d*\):.*', '\1', '')
    let msg = substitute(output, '^\%(Syntax\|Haml\) error on line \d*:\(.*\)', '\1', '')
    return [{'lnum' : line, 'text' : msg, 'bufnr': bufnr(""), 'type': 'E' }]
  endif
  return []
endf


function syntastic#Sass()
  throw "TODO"

  "use compass imports if available
  if g:syntastic_sass_imports == 0 && executable("compass")
    let g:syntastic_sass_imports = system("compass imports")
  else
    let g:syntastic_sass_imports = ""
  endif

  let makeprg='sass '.g:syntastic_sass_imports.' --check '.shellescape(expand('%'))
  let errorformat = '%ESyntax %trror:%m,%C        on line %l of %f,%Z%m'
  let errorformat .= ',%Wwarning on line %l:,%Z%m,Syntax %trror on line %l: %m'
  let loclist = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })

  let bn = bufnr("")
  for i in loclist
    let i['bufnr'] = bn
  endfor

  return loclist
endfunction


function syntastic#CUDA()
  throw "TODO"

    let makeprg = g:syntastic_nvcc_binary.' --cuda -O0 -I . -Xcompiler -fsyntax-only '.shellescape(expand('%')).' -o /dev/null'
    "let errorformat =  '%-G%f:%s:,%f:%l:%c: %m,%f:%l: %m'
    let errorformat =  '%*[^"]"%f"%*\D%l: %m,"%f"%*\D%l: %m,%-G%f:%l: (Each undeclared identifier is reported only once,%-G%f:%l: for each function it appears in.),%f:%l:%c:%m,%f(%l):%m,%f:%l:%m,"%f"\, line %l%*\D%c%*[^ ] %m,%D%*\a[%*\d]: Entering directory `%f'',%X%*\a[%*\d]: Leaving directory `%f'',%D%*\a: Entering directory `%f'',%X%*\a: Leaving directory `%f'',%DMaking %*\a in %f,%f|%l| %m'

    if expand('%') =~? '\%(.h\|.hpp\|.cuh\)$'
        if exists('g:syntastic_cuda_check_header')
            let makeprg = 'echo > .syntastic_dummy.cu ; '.g:syntastic_nvcc_binary.' --cuda -O0 -I . .syntastic_dummy.cu -Xcompiler -fsyntax-only -include '.shellescape(expand('%')).' -o /dev/null'
        else
            return []
        endif
    endif
    return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endfunction




" TODO LUA
" function! SyntaxCheckers_lua_Term(pos)
"     let near = matchstr(a:pos['text'], "near '[^']\\+'")
"     let result = ''
"     if len(near) > 0
"         let near = split(near, "'")[1]
"         if near == '<eof>'
"             let p = getpos('$')
"             let a:pos['lnum'] = p[1]
"             let a:pos['col'] = p[2]
"             let result = '\%'.p[2].'c'
"         else
"             let result = '\V'.near
"         endif
"         let open = matchstr(a:pos['text'], "(to close '[^']\\+' at line [0-9]\\+)")
"         if len(open) > 0
"             let oline = split(open, "'")[1:2]
"             let line = 0+strpart(oline[1], 9)
"             call matchadd('SpellCap', '\%'.line.'l\V'.oline[0])
"         endif
"     endif
"     return result
" endfunction
" 
" function! SyntaxCheckers_lua_GetLocList()
" 
"     let loclist = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
" 
"     let bufn = bufnr('')
"     for pos in loclist
"         let pos['bufnr'] = bufn
"         let pos['type'] = 'E'
"     endfor
" 
"     call syntastic#HighlightErrors(loclist, function("SyntaxCheckers_lua_Term"))
" 
"     return loclist
" endfunction
"
"
"

function! syntastic#SyntaxCheckers_python_Term(i)
  throw "TODO"
    if a:i['type'] ==# 'E'
        let a:i['text'] = "Syntax error"
    endif
    if match(a:i['text'], 'is assigned to but never used') > -1
                \ || match(a:i['text'], 'imported but unused') > -1
                \ || match(a:i['text'], 'undefined name') > -1
                \ || match(a:i['text'], 'redefinition of unused') > -1

        let term = split(a:i['text'], "'", 1)[1]
        return '\V'.term
    endif
    return ''
endfunction

" xhtml 
function syntastic#Tidy()
  throw "TODO"
  " TODO: join this with html.vim DRY's sake?
    let tidy_opts = {
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
    return get(tidy_opts, &fileencoding, '-utf8')

    let encopt = s:TidyEncOptByFenc()
    let makeprg="tidy ".encopt." -xml -e ".shellescape(expand('%'))
    let errorformat='%Wline %l column %c - Warning: %m,%Eline %l column %c - Error: %m,%-G%.%#,%-G%.%#'
    let loclist = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })

    "the file name isnt in the output so stick in the buf num manually
    for i in loclist
        let i['bufnr'] = bufnr("")
    endfor

    return loclist
endfunction
