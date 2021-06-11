if !has('float') || !has('timers')
  let g:smoothie_enabled = 0
  echohl WarningMsg
  echom 'vim-smoothie needs +timers and +float'
  echohl None
  finish
endif

if has('nvim') || has('patch-8.2.1978')
  noremap <silent> <Plug>(SmoothieDownwards) <cmd>call smoothie#downwards()           <CR>
  noremap <silent> <Plug>(SmoothieUpwards)   <cmd>call smoothie#upwards()             <CR>
  noremap <silent> <Plug>(SmoothieForwards)  <cmd>call smoothie#forwards()            <CR>
  noremap <silent> <Plug>(SmoothieBackwards) <cmd>call smoothie#backwards()           <CR>
  noremap <silent> <Plug>(Smoothie_gg)       <cmd>call smoothie#cursor_movement('gg') <CR>
  noremap <silent> <Plug>(Smoothie_G)        <cmd>call smoothie#cursor_movement('G')  <CR>
  noremap <silent> <Plug>(SmoothieTop)       <cmd>call smoothie#top()                 <CR>
  noremap <silent> <Plug>(SmoothieMiddle)    <cmd>call smoothie#middle()              <CR>
  noremap <silent> <Plug>(SmoothieBottom)    <cmd>call smoothie#bottom()              <CR>

  if !get(g:, 'smoothie_no_default_mappings', v:false)
    silent! map <unique> <C-D>      <Plug>(SmoothieDownwards)
    silent! map <unique> <C-U>      <Plug>(SmoothieUpwards)
    silent! map <unique> <C-F>      <Plug>(SmoothieForwards)
    silent! map <unique> <S-Down>   <Plug>(SmoothieForwards)
    silent! map <unique> <PageDown> <Plug>(SmoothieForwards)
    silent! map <unique> <C-B>      <Plug>(SmoothieBackwards)
    silent! map <unique> <S-Up>     <Plug>(SmoothieBackwards)
    silent! map <unique> <PageUp>   <Plug>(SmoothieBackwards)
    if get(g:, 'smoothie_experimental_mappings', v:false)
      silent! map <unique> gg         <Plug>(Smoothie_gg)
      silent! map <unique> G          <Plug>(Smoothie_G)
      silent! map <unique> zt         <Plug>(SmoothieTop)
      silent! map <unique> zz         <Plug>(SmoothieMiddle)
      silent! map <unique> z.         <Plug>(SmoothieMiddle)
      silent! map <unique> zb         <Plug>(SmoothieBottom)
    endif
  endif
else
  nnoremap <silent> <Plug>(SmoothieDownwards) :<C-U>call smoothie#downwards()           <CR>
  nnoremap <silent> <Plug>(SmoothieUpwards)   :<C-U>call smoothie#upwards()             <CR>
  nnoremap <silent> <Plug>(SmoothieForwards)  :<C-U>call smoothie#forwards()            <CR>
  nnoremap <silent> <Plug>(SmoothieBackwards) :<C-U>call smoothie#backwards()           <CR>
  nnoremap <silent> <Plug>(Smoothie_gg)       :<C-U>call smoothie#cursor_movement('gg') <CR>
  nnoremap <silent> <Plug>(Smoothie_G)        :<C-U>call smoothie#cursor_movement('G')  <CR>
  nnoremap <silent> <Plug>(SmoothieTop)        :<C-U>call smoothie#top()                 <CR>
  nnoremap <silent> <Plug>(SmoothieMiddle)     :<C-U>call smoothie#middle()              <CR>
  nnoremap <silent> <Plug>(SmoothieBottom)     :<C-U>call smoothie#bottom()              <CR>

  if !get(g:, 'smoothie_no_default_mappings', v:false)
    silent! nmap <unique> <C-D>      <Plug>(SmoothieDownwards)
    silent! nmap <unique> <C-U>      <Plug>(SmoothieUpwards)
    silent! nmap <unique> <C-F>      <Plug>(SmoothieForwards)
    silent! nmap <unique> <S-Down>   <Plug>(SmoothieForwards)
    silent! nmap <unique> <PageDown> <Plug>(SmoothieForwards)
    silent! nmap <unique> <C-B>      <Plug>(SmoothieBackwards)
    silent! nmap <unique> <S-Up>     <Plug>(SmoothieBackwards)
    silent! nmap <unique> <PageUp>   <Plug>(SmoothieBackwards)
    if get(g:, 'smoothie_experimental_mappings', v:false)
      silent! nmap <unique> gg         <Plug>(Smoothie_gg)
      silent! nmap <unique> G          <Plug>(Smoothie_G)
      silent! map <unique> zt          <Plug>(SmoothieTop)
      silent! map <unique> zz          <Plug>(SmoothieMiddle)
      silent! map <unique> z.          <Plug>(SmoothieMiddle)
      silent! map <unique> zb          <Plug>(SmoothieBottom)
    endif
  endif
endif

" vim: et ts=2
