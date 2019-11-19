nnoremap <silent> <Plug>(SmoothieDownwards) :<C-U>call smoothie#downwards() <CR>
nnoremap <silent> <Plug>(SmoothieUpwards)   :<C-U>call smoothie#upwards()   <CR>
nnoremap <silent> <Plug>(SmoothieForwards)  :<C-U>call smoothie#forwards()  <CR>
nnoremap <silent> <Plug>(SmoothieBackwards) :<C-U>call smoothie#backwards() <CR>

if get(g:, 'smoothie_use_default_mappings', v:true)
  silent! map <unique> <C-D>      <Plug>(SmoothieDownwards)
  silent! map <unique> <C-U>      <Plug>(SmoothieUpwards)
  silent! map <unique> <C-F>      <Plug>(SmoothieForwards)
  silent! map <unique> <S-Down>   <Plug>(SmoothieForwards)
  silent! map <unique> <PageDown> <Plug>(SmoothieForwards)
  silent! map <unique> <C-B>      <Plug>(SmoothieBackwards)
  silent! map <unique> <S-Up>     <Plug>(SmoothieBackwards)
  silent! map <unique> <PageUp>   <Plug>(SmoothieBackwards)
en
