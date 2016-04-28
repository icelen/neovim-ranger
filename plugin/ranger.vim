" based on
" https://github.com/Mizuchi/vim-ranger/blob/master/plugin/ranger.vim

function! s:RangerJobHandler(job_id, data, event)
    if a:event == 'exit'
        call s:FileHandler()
    endif
endfunction

function! s:FileHandler()
    let buftoclose = bufnr('%')
    if filereadable(s:fullfilename)
        exec '!cat ' . s:fullfilename . '> ~/chosenFiles'
        let names = readfile(s:fullfilename)
        if empty(names)
            return
        endif
    endif
    exec 'bd!' . buftoclose
    for name in names[0:]
        exec 'edit! ' . fnameescape(name)
        filetype detect
    endfor
    redraw!
endfunction

function! s:FormatBuffer()
    setlocal
                \ bufhidden=wipe
                \ nobuflisted
                \ noswapfile
    if exists(':AirlineRefresh')
        silent! AirlineRefresh
    endif
    redraw!
endfunction

function! s:RangerChooser(dirname, commanded)
    if isdirectory(a:dirname)
        let s:temp = tempname()
        let s:callbacks = {
                    \ 'on_stdout': function('s:RangerJobHandler'),
                    \ 'on_stderr': function('s:RangerJobHandler'),
                    \ 'on_exit': function('s:RangerJobHandler')
                    \}
        if a:commanded == 1
            enew
        endif

        let s:fullfilename = shellescape(s:temp)

        if exists(':terminal')
            call termopen('ranger --choosefiles=' . s:fullfilename. ' ' . shellescape(a:dirname), s:callbacks) | startinsert | call s:FormatBuffer()
        else
            call s:VanillaRanger()
        endif
    endif
endfunction

function! s:VanillaRanger()
    exec 'silent !ranger --choosefiles=' . s:fullfilename . ' ' . shellescape(a:dirname)

    if filereadable(s:fullfilename)
        let names = readfile(s:fullfilename)
        if empty(names)
            return
        endif
    else
        exec 'bd'
    endif
    for name in names[0:]
        exec 'silent edit! ' . fnameescape(name)
        filetype detect
    endfor
    redraw!
endfunction

function! s:ExplorerWrapper(arg)
    if isdirectory(a:arg)
        call s:RangerChooser(a:arg, 1)
    elseif (a:arg == '')
        call s:RangerChooser(getcwd(), 1)
    else
    endif
endfunction

let g:loaded_netrwPlugin = 'disable'

augroup RangerExplorer
    au!
    au BufEnter * silent call s:RangerChooser(expand('<amatch>'), 0)
augroup END

command! -nargs=? -bar -complete=dir Explore silent call s:ExplorerWrapper('<args>')
