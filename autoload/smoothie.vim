""
" This variable is used to inform the s:step_*() functions about whether the
" current movement is a cursor movement or a scroll movement.  Used for
" motions like gg and G
let s:cursor_movement = v:false

""
" This variable is needed to let the s:step_down() function know whether to
" continue scrolling after reaching EOL (as in ^F) or not (^B, ^D, ^U, etc.)
"
" NOTE: This variable "MUST" be set to v:false in "every" function that
" invokes motion (except smoothie#forwards, where it must be set to v:true)
let s:ctrl_f_invoked = v:false

if !exists('g:smoothie_enabled')
  ""
  " Set it to 0 to disable vim-smoothie.  Useful for very slow connections.
  let g:smoothie_enabled = 1
endif

if !exists('g:smoothie_update_interval')
  ""
  " Time (in milliseconds) between subseqent screen/cursor postion updates.
  " Lower value produces smoother animation.  Might be useful to increase it
  " when running Vim over low-bandwidth/high-latency connections.
  let g:smoothie_update_interval = 20
endif

if !exists('g:smoothie_base_speed')
  ""
  " Base scrolling speed (in lines per second), to be taken into account by
  " the velocity calculation algorithm.  Can be decreased to achieve slower
  " (and easier to follow) animation.
  let g:smoothie_base_speed = 10
endif

if !exists('g:smoothie_break_on_reverse')
  ""
  " Stop immediately if we're moving and the user requested moving in opposite
  " direction.  It's mostly useful at very low scrolling speeds, hence
  " disabled by default.
  let g:smoothie_break_on_reverse = 0
endif

""
" Execute {command}, but saving 'scroll' value before, and restoring it
" afterwards.  Useful for some commands (such as ^D or ^U), which overwrite
" 'scroll' permanently if used with a [count].
function s:execute_preserving_scroll(command)
  let l:saved_scroll = &scroll
  let l:saved_scrolloff = 0
  if &scrolloff
    let l:saved_scrolloff = &scrolloff
    let &scrolloff = 0
  endif
  execute a:command
  let &scroll = l:saved_scroll
  if l:saved_scrolloff
    let &scrolloff = l:saved_scrolloff
  endif
endfunction

""
" Scroll the window up by one line, or move the cursor up if the window is
" already at the top.  Return 1 if cannot move any higher.
function s:step_up()
  if line('.') > 1
    if s:cursor_movement
      exe 'normal! k'
      return 0
    endif
    call s:execute_preserving_scroll("normal! 1\<C-U>")
    return 0
  else
    return 1
  endif
endfunction

""
" Scroll the window down by one line, or move the cursor down if the window is
" already at the bottom.  Return 1 if cannot move any lower.
function s:step_down()
  if !(line('.') < line('$')) && !s:ctrl_f_invoked
    " cursor is at last line of buffer, and movement is not Ctrl-F
    " cannot move
    return 1
  endif
  if line('.') < line('$')
    if s:cursor_movement
      exe 'normal! j'
      return 0
    endif
    " NOTE: the three lines of code following this comment block
    " have been implemented as a temporary workaround for a vim issue
    " regarding Ctrl-D and folds.
    "
    " See: neovim/neovim#13080
    if foldclosedend('.') != -1
      call cursor(foldclosedend('.'), col('.'))
    endif
    call s:execute_preserving_scroll("normal! 1\<C-D>")
    if s:ctrl_f_invoked && (winheight(0) - winline()) >= (line('$') - line('.'))
      " ^F is pressed, and the last line of the buffer is visible
      " scroll window to keep cursor position fixed
      call s:execute_preserving_scroll("normal! \<C-E>")
    endif
    return 0
  elseif s:ctrl_f_invoked && winline() > 1
    " cursor is already on last line of buffer, but not on last line of window
    " ^F can scroll more
    call s:execute_preserving_scroll("normal! \<C-E>")
    return 0
  else
    return 1
  endif
endfunction

""
" Perform as many steps up or down to move {lines} lines from the starting
" position (negative {lines} value means to go up).  Return 1 if hit either
" top or bottom, and cannot move further.
function s:step_many(lines)
  let l:remaining_lines = a:lines
  while 1
    if l:remaining_lines < 0
      if s:step_up()
        return 1
      endif
      let l:remaining_lines += 1
    elseif l:remaining_lines > 0
      if s:step_down()
        return 1
      endif
      let l:remaining_lines -= 1
    else
      return 0
    endif
  endwhile
endfunction

""
" A Number indicating how many lines do we need yet to move down (or up, if
" it's negative), to achieve what the user wants.
let s:target_displacement = 0

""
" A Float between -1.0 and 1.0 keeping our position between integral lines,
" used to make the animation smoother.
let s:subline_position = 0.0

""
" Start the animation timer if not already running.  Should be called when
" updating the target, when there's a chance we're not already moving.
function s:start_moving()
  if !exists('s:timer_id')
    let s:timer_id = timer_start(g:smoothie_update_interval, function('s:movement_tick'), {'repeat': -1})
  endif
endfunction

""
" Stop any movement immediately, and disable the animation timer to conserve
" power.
function s:stop_moving()
  let s:target_displacement = 0
  let s:subline_position = 0.0
  if exists('s:timer_id')
    call timer_stop(s:timer_id)
    unlet s:timer_id
  endif
endfunction

""
" Calculate optimal movement velocity (in lines per second, negative value
" means to move upwards) for the next animation frame.
"
" TODO: current algorithm is rather crude, would be good to research better
" alternatives.
function s:compute_velocity()
  " return g:smoothie_base_speed * (s:target_displacement + s:subline_position)
  let l:foo = g:smoothie_base_speed * (s:target_displacement + s:subline_position)
  let l:abs = abs(l:foo)
  let l:sgn = l:foo / l:abs
  return pow(l:abs,0.9)*l:sgn
endfunction

""
" Execute single animation frame.  Called periodically by a timer.  Accepts a
" throwaway parameter: the timer ID.
function s:movement_tick(_)
  if s:target_displacement == 0
    call s:stop_moving()
    return
  endif

  let l:subline_step_size = s:subline_position + (g:smoothie_update_interval/1000.0 * s:compute_velocity())
  let l:step_size = float2nr(trunc(l:subline_step_size))

  if abs(l:step_size) > abs(s:target_displacement)
    " clamp step size to prevent overshooting the target
    let l:step_size = s:target_displacement
  end

  if s:step_many(l:step_size)
    " we've collided with either buffer end
    call s:stop_moving()
    if !(&belloff =~# 'all\|error')
      " bell
      let l:belloff = &belloff
      set belloff=
      exe "normal \<Esc>"
      exe 'set belloff=' . l:belloff
    endif
  else
    let s:target_displacement -= l:step_size
    let s:subline_position = l:subline_step_size - l:step_size
  endif

  if l:step_size
    " Usually Vim handles redraws well on its own, but without explicit redraw
    " I've encountered some sporadic display artifacts.  TODO: debug further.
    redraw
  endif
endfunction

""
" Set a new target where we should move to (in lines, relative to our current
" position).  If we're already moving, try to do the smart thing, taking into
" account our progress in reaching the target set previously.
function s:update_target(lines)
  if g:smoothie_break_on_reverse && s:target_displacement * a:lines < 0
    call s:stop_moving()
  else
    " Cursor movements are very delicate. Since the displacement for cursor
    " movements is calulated from the "current" line, so immediately stop
    " moving, otherwise we will end up at the wrong line.
    if s:cursor_movement
      call s:stop_moving()
    endif
    let s:target_displacement += a:lines
    call s:start_moving()
  endif
endfunction

""
" Helper function to calculate the actual number of screen lines from a line
" to another.  Useful for properly handling folds in case of cursor movements.
function s:calculate_screen_lines(from, to)
  let l:from = a:from
  let l:to = a:to
  let l:from = (foldclosed(l:from) != -1 ? foldclosed(l:from) : l:from)
  let l:to = (foldclosed(l:to) != -1 ? foldclosed(l:to) : l:to)
  if l:from == l:to
    return 0
  endif
  let l:lines = 0
  let l:linenr = l:from
  while l:linenr != l:to
    if l:linenr < l:to
      let l:lines +=1
      let l:linenr = (foldclosedend(l:linenr) != -1 ? foldclosedend(l:linenr) : l:linenr)
      let l:linenr += 1
    elseif l:linenr > l:to
      let l:lines -= 1
      let l:linenr = (foldclosed(l:linenr) != -1 ? foldclosed(l:linenr) : l:linenr)
      let l:linenr -= 1
    endif
  endwhile
  return l:lines
endfunction

""
" Helper function to set 'scroll' to [count], similarly to what native ^U and
" ^D commands do.
function s:count_to_scroll()
  if v:count
    let &scroll=v:count
  end
endfunction

""
" Smooth equivalent to ^D.
function smoothie#downwards()
  if !g:smoothie_enabled
    exe "normal! \<C-d>"
    return
  endif
  let s:ctrl_f_invoked = v:false
  call s:count_to_scroll()
  call s:update_target(&scroll)
endfunction

""
" Smooth equivalent to ^U.
function smoothie#upwards()
  if !g:smoothie_enabled
    exe "normal! \<C-u>"
    return
  endif
  let s:ctrl_f_invoked = v:false
  call s:count_to_scroll()
  call s:update_target(-&scroll)
endfunction

""
" Smooth equivalent to ^F.
function smoothie#forwards()
  if !g:smoothie_enabled
    exe "normal! \<C-f>"
    return
  endif
  let s:ctrl_f_invoked = v:true
  call s:update_target(winheight(0) * v:count1)
endfunction

""
" Smooth equivalent to ^B.
function smoothie#backwards()
  if !g:smoothie_enabled
    exe "normal! \<C-b>"
    return
  endif
  let s:ctrl_f_invoked = v:false
  call s:update_target(-winheight(0) * v:count1)
endfunction

" Smoothie equivalent to gg.
function smoothie#gg()
  let s:cursor_movement = v:true
  let s:ctrl_f_invoked = v:false
  if !g:smoothie_enabled || mode(1) =~# 'o' && mode(1) =~? 'no'
    " If in operator pending mode, disable vim-smoothie and force the movement
    " to be line-wise, because gg was originally linewise.
    " Uses the normal non-smooth version of gg.
    exe 'normal! ' . (mode(1) ==# 'no' ? 'V' : '') . v:count . 'gg'
    return
  endif
  " gg behaves like a jump-command
  " so, append current position to the jumplist
  " but before that, save v:count into a variable
  let l:target = v:count1
  let l:target = (l:target > line('$') ? line('$') : l:target)
  let l:target = (foldclosed(l:target) != -1 ? foldclosed(l:target) : l:target)
  if foldclosed('.') == l:target
    let s:cursor_movement = v:false
    return
  endif
  execute "normal! m'"
  call s:update_target(s:calculate_screen_lines(line('.'), l:target))
  " suspend further commands till the destination is reached
  " see point (3) of https://github.com/psliwka/vim-smoothie/issues/1#issuecomment-560158642
  while line('.') != l:target
    exe 'sleep ' . g:smoothie_update_interval . ' m'
  endwhile
  " reset s:cursor_movement to false
  let s:cursor_movement = v:false
  " :help 'startofline'
  if &startofline
    call cursor(line('.'), match(getline('.'),'\S')+1)
  endif
endfunction

" Smoothie equivalent to G.
function smoothie#G()
  let s:cursor_movement = v:true
  let s:ctrl_f_invoked = v:false
  if !g:smoothie_enabled || mode(1) =~# 'o' && mode(1) =~? 'no'
    " If in operator pending mode, disable vim-smoothie and force the movement
    " to be line-wise, because G was originally linewise.
    " Uses the normal non-smooth version of G.
    exe 'normal! ' . (mode(1) ==# 'no' ? 'V' : '') . v:count . 'G'
    return
  endif
  " G behaves like a jump-command
  " so, append current position to the jumplist
  " but before that, save v:count into a variable
  let l:target = (v:count ? v:count : line('$'))
  let l:target = (l:target > line('$') ? line('$') : l:target)
  let l:target = (foldclosed(l:target) != -1 ? foldclosed(l:target) : l:target)
  if foldclosed('.') == l:target
    let s:cursor_movement = v:false
    return
  endif
  execute "normal! m'"
  call s:update_target(s:calculate_screen_lines(line('.'), l:target))
  " suspend further commands till the destination is reached
  " see point (3) of https://github.com/psliwka/vim-smoothie/issues/1#issuecomment-560158642
  while line('.') != l:target
    exe 'sleep ' . g:smoothie_update_interval . ' m'
  endwhile
  " reset s:cursor_movement to false
  let s:cursor_movement = v:false
  " :help 'startofline'
  if &startofline
    call cursor(line('.'), match(getline('.'),'\S')+1)
  endif
endfunction

" vim: et ts=2
