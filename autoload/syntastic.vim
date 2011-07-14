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
