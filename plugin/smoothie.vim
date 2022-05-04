""
" Check if we're running a compatible version of (Neo)Vim
if !has('nvim')
  if !has('patch-8.2.1978')
    echohl WarningMsg
    echom 'vim-smoothie disabled: the plugin requires Neovim, or Vim 8.2.1978 or later'
    echohl None
    finish
  endif
  if !has('float') || !has('timers')
    echohl WarningMsg
    echom 'vim-smoothie disabled: the plugin requires Vim to be compiled with `+timers` and `+float`'
    echohl None
    finish
  endif
endif

""
" Check if user has any deprecated options in their config
for deprecated_option in ['smoothie_break_on_reverse']
  if get(g:, deprecated_option, v:false)
    echohl WarningMsg
    echom 'vim-smoothie warning: the `' . deprecated_option . '` option is no longer available.'
    echohl None
  endif
endfor

""
" Initialize user-facing configuration options
if !exists('g:smoothie_enabled')
  ""
  " Set it to 0 to disable the plugin.  Useful for very slow connections.
  let g:smoothie_enabled = 1
endif
if !exists('g:smoothie_no_default_mappings')
  ""
  " If true, will prevent the plugin from remapping default scrolling keys
  let g:smoothie_no_default_mappings = v:false
endif
if !exists('g:smoothie_experimental_mappings')
  ""
  " Set this to true to enable additional, experimental mappings (currently `gg` and `G`).
  let g:smoothie_experimental_mappings = v:false
endif
if !exists('g:smoothie_remapped_commands')
  ""
  " List of commands which smoothened alternatives will be mapped for
  if !g:smoothie_no_default_mappings
    let g:smoothie_remapped_commands = ['<C-D>', '<C-U>', '<C-F>', '<S-Down>', '<PageDown>', '<C-B>', '<S-Up>', '<PageUp>', 'z+', 'z^', 'zt', 'z.', 'zz', 'z-', 'zb']
    if g:smoothie_experimental_mappings
      let g:smoothie_remapped_commands += ['gg', 'G']
    endif
  else
    let g:smoothie_remapped_commands = []
  endif
endif

""
" Add mappings to override commands which should be smoothened
for remapped_command in g:smoothie_remapped_commands
  for mapping_command in ['nnoremap', 'vnoremap']
    execute 'silent! ' . mapping_command . ' <unique> ' . remapped_command . ' <cmd>call smoothie#do("' . substitute(remapped_command, '<', '\\<lt>', '') . '") <CR>'
  endfor
endfor

""
" Old mappings kept for backward compatibility with legacy configurations
noremap <silent> <Plug>(SmoothieDownwards) <cmd>call smoothie#downwards()           <CR>
noremap <silent> <Plug>(SmoothieUpwards)   <cmd>call smoothie#upwards()             <CR>
noremap <silent> <Plug>(SmoothieForwards)  <cmd>call smoothie#forwards()            <CR>
noremap <silent> <Plug>(SmoothieBackwards) <cmd>call smoothie#backwards()           <CR>

" vim: et ts=2
