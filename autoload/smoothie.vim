function! s:editor_supports_fast_redraw() abort
  " Currently enabled only for Neovim, because it causes screen flickering on
  " regular Vim.
  return has('nvim')
endfunction

function! s:terminal_supports_fast_redraw() abort
  " Currently only Kitty is known not to cause any flickering when calling
  " `:mode`.
  return $TERM ==# 'xterm-kitty'
endfunction

""
" Note: the configuration options mentioned there are intentionally hidden
" from the user, since they're not guaranteed to be backward-compatible with
" future releases of the plugin. Change them at your own risk!

if !exists('g:smoothie_update_interval')
  ""
  " Time (in milliseconds) between subsequent screen/cursor position updates.
  " Lower value produces smoother animation.  Might be useful to increase it
  " when running Vim over low-bandwidth/high-latency connections.
  let g:smoothie_update_interval = 20
endif

if !exists('g:smoothie_speed_constant_factor')
  ""
  " This value controls constant term of the velocity curve. Increasing this
  " boosts primarily cursor speed at the end of animation.
  let g:smoothie_speed_constant_factor = 10
endif

if !exists('g:smoothie_speed_linear_factor')
  ""
  " This value controls linear term of the velocity curve. Increasing this
  " boosts primarily cursor speed at the beginning of animation.
  let g:smoothie_speed_linear_factor = 10
endif

if !exists('g:smoothie_speed_exponentiation_factor')
  ""
  " This value controls exponent of the power function in the velocity curve.
  " Generally should be less or equal to 1.0. Lower values produce longer but
  " perceivably smoother animation.
  let g:smoothie_speed_exponentiation_factor = 0.9
endif

if !exists('g:smoothie_redraw_at_finish')
  ""
  " Force screen redraw when the animation is finished, which clears sporadic
  " display artifacts which I encountered f.ex. when scrolling through buffers
  " containing emoji. Enabled by default only if both editor and terminal
  " supports doing this in a glitch-free way.
  let g:smoothie_redraw_at_finish = s:editor_supports_fast_redraw() && s:terminal_supports_fast_redraw()
endif

let s:target_view = {}

let s:subline_progress_view = {}

let s:animated_view_elements = ['lnum', 'topline']

""
" Start the animation timer if not already running.  Should be called when
" updating the target, when there's a chance we're not already moving.
function! s:start_moving() abort
  call s:ensure_subline_progress_view_initialized()
  if !exists('s:timer_id')
    let s:timer_id = timer_start(g:smoothie_update_interval, function('s:animation_tick'), {'repeat': -1})
    let s:last_tick_time = reltime()
  endif
endfunction

function! s:ensure_subline_progress_view_initialized() abort
  if empty(s:subline_progress_view)
    for key in s:animated_view_elements
      let s:subline_progress_view[key] = 0.0
    endfor
  endif
endfunction

""
" Ensure the window and the cursor is positioned at their final destinations,
" and disable the animation timer to conserve power.
function! s:finish_moving() abort
  call winrestview(s:target_view)
  if g:smoothie_redraw_at_finish
    mode
  endif
  let s:target_view = {}
  let s:subline_progress_view = {}
  if exists('s:timer_id')
    call timer_stop(s:timer_id)
    unlet s:timer_id
  endif
endfunction

""
" Skip animation and jump to target position immediately if we're moving and
" the user is about to leave the window or switch to a different buffer.
function! s:handle_leave_event() abort
  if !empty(s:target_view)
    call s:finish_moving()
  endif
endfunction

augroup smoothie_leave_handlers
  autocmd!
  autocmd WinLeave,BufLeave * call s:handle_leave_event()
augroup end

""
" TODO: current algorithm is rather crude, would be good to research better
" alternatives.
function! s:compute_velocity_element(target_distance_element) abort
  let l:absolute_speed = g:smoothie_speed_constant_factor + g:smoothie_speed_linear_factor * pow(abs(a:target_distance_element), g:smoothie_speed_exponentiation_factor)
  if a:target_distance_element < 0
    return -l:absolute_speed
  else
    return l:absolute_speed
  endif
endfunction

function! s:compute_target_distance() abort
  let l:result = {}
  for [key, value] in items(s:filter_dict(winsaveview(), s:animated_view_elements))
    let l:result[key] = s:target_view[key] - value - s:subline_progress_view[key]
  endfor
  return l:result
endfunction

function! s:compute_velocity(target_distance) abort
  let l:result = {}
  for [key, value] in items(a:target_distance)
    let l:result[key] = s:compute_velocity_element(value)
  endfor
  return l:result
endfunction

function! s:compute_animation_step(target_distance, step_duration) abort
  let l:result = {}
  for [key, value] in items(s:compute_velocity(a:target_distance))
    let l:result[key] = value * a:step_duration
    if abs(l:result[key]) > abs(a:target_distance[key])
      " clamp step size to prevent overshooting the target
      let l:result[key] = a:target_distance[key]
    end
  endfor
  return l:result
endfunction

function! s:filter_dict(source, persisted_keys) abort
  let l:result = {}
  for key in a:persisted_keys
    let l:result[key] = a:source[key]
  endfor
  return result
endfunction

""
" Equivalent to winrestview(), but tries to avoid actually calling
" winrestview() and tries to restore the view using normal mode commands if
" possible.  This improves redraw smoothness and minimises glitches,
" especially on slow terminals.
function! s:winrestview_optimized(new_view) abort
  for key in ['topline', 'lnum']
    let l:distance = a:new_view[key] - winsaveview()[key]
    if l:distance == 0
      continue
    endif
    if key ==# 'topline'
      if l:distance > 0
        execute 'normal! ' . l:distance . "\<C-E>"
      else
        execute 'normal! ' . -l:distance . "\<C-Y>"
      endif
    elseif key ==# 'lnum'
      if l:distance > 0
        execute 'normal! ' . l:distance . 'j'
      else
        execute 'normal! ' . -l:distance . 'k'
      endif
    endif
  endfor
  let l:view_after_optimization = s:filter_dict(winsaveview(), keys(a:new_view))
  let l:remaining_view_changes = {}
  for [key, value] in items(view_after_optimization)
    if a:new_view[key] != value
      let l:remaining_view_changes[key] = a:new_view[key]
    endif
  endfor
  if !empty(l:remaining_view_changes)
    call winrestview(l:remaining_view_changes)
  endif
endfunction

function! s:perform_animation_step(step_duration) abort
  let l:target_distance = s:compute_target_distance()
  let l:new_position = s:filter_dict(winsaveview(), s:animated_view_elements)
  let l:animation_step = s:compute_animation_step(l:target_distance, a:step_duration)
  let l:finished_moving = v:true
  for [key, value] in items(l:animation_step)
    if l:new_position[key] == s:target_view[key]
      continue
    else
      let l:finished_moving = v:false
    endif
    let l:integer_step_size = float2nr(trunc(value+s:subline_progress_view[key]))
    if l:integer_step_size != 0
      let l:new_position[key] = l:new_position[key] + l:integer_step_size
    endif
    let s:subline_progress_view[key] += value - l:integer_step_size
  endfor
  call s:winrestview_optimized(l:new_position)
  return l:finished_moving
endfunction

""
" Execute single animation frame.  Called periodically by a timer.  Accepts a
" throwaway parameter: the timer ID.
function! s:animation_tick(_) abort
  let l:current_step_duration = reltimefloat(reltime(s:last_tick_time))
  let s:last_tick_time = reltime()
  let l:finished_moving = s:perform_animation_step(l:current_step_duration)
  if l:finished_moving
    call s:finish_moving()
  endif
endfunction

function! s:update_target(command, count) abort
  let l:current_view = winsaveview()
  if !empty(s:target_view)
    call winrestview(s:target_view)
  endif
  execute 'normal! ' . a:count . a:command
  let s:target_view = winsaveview()
  call winrestview(l:current_view)
endfunction

function! smoothie#do(command) abort
  if v:count == 0
    let l:count = ''
  else
    let l:count = v:count
  endif
  if g:smoothie_enabled
    call s:update_target(a:command, l:count)
    call s:start_moving()
  else
    execute 'normal! ' . l:count . a:command
  endif
endfunction

""
" Old interface kept for backward compatibility with legacy configurations
function! smoothie#downwards() abort
  call smoothie#do("\<C-D>")
endfunction
function! smoothie#upwards() abort
  call smoothie#do("\<C-U>")
endfunction
function! smoothie#forwards() abort
  call smoothie#do("\<C-F>")
endfunction
function! smoothie#backwards() abort
  call smoothie#do("\<C-B>")
endfunction

" vim: et ts=2
