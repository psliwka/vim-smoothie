vim-smoothie: Smooth scrolling for Vim done right🥤
===================================================

This (neo)vim plugin makes scrolling nice and _smooth_. Find yourself
completely lost every time you press `Ctrl-D` or `Ctrl-F`? You might want to
give _vim-smoothie_ a try!

Installation
------------

You will need reasonably new Vim or Neovim with timers support. Vim 8+ or
Neovim 0.3+ should do the trick.

Install the plugin using your favorite plugin manager, for example [vim-plug]:
```
Plug 'psliwka/vim-smoothie'
```

Alternatives, a.k.a. why create yet another plugin
--------------------------------------------------

There are many other Vim plugins attempting to resolve the same problem. The
most intresting one is [sexy_scroller.vim], which covers way more movement
commands than vim-smoothie will ever do. Unfortunately, it also suffers from
frequent visual artifacts, such as erratic screen jumps and animation
jittering, impairing visual orientation and breaking the user experience. Many
of these bugs are nearly impossible to fix due to the plugin's internal design.
Hence, vim-smoothie was born, focusing on stable, bug-free, _smooth_
experience, at a cost of smaller feature set.

The table below summarizes key differences between vim-smoothie and three other
popular smooth scrolling plugins I've used in the past: [sexy_scroller.vim],
[comfortable-motion.vim], and [vim-smooth-scroll].

|  | vim-smoothie | [sexy_scroller.vim] | [comfortable-motion.vim] | [vim-smooth-scroll] |
|---|:---:|:---:|:---:|:---:|
| Supported commands | `^D` `^U` `^F` `^B` | A lot❤️ | `^D` `^U` `^F` `^B` | `^D` `^U` `^F` `^B` |
| Erratic screen jumps and jittering now and then | Nope | A lot💔 | Nope | Nope |
| Scrolling distance is proportional to window height | ✅ | ✅ | ❌ | ✅ |
| Easing out (soft-stop) | ✅ | ✅ | ✅ | ❌ |
| Supports setting `[count]` before movement (f.ex. `3^F` to scroll down 3 pages) | ✅ | ✅ | ❌ | ❌ |
| Respects `scroll` and `startofline` options | ✅ | ✅ | ❌ | ❌ |
| `^D` and `^U` behave correctly near buffer ends, just moving the cursor instead of scrolling the window | ✅ | ✅ | ❌ | ❌ |
| Pun in name | ✅ | ✅ | ❌ | ❌ |

Known issues/incompatibilities
------------------------------

vim-smoothie strives to remain fully compatible with native commands it
replaces. That is, every command should still behave exactly as described in
`:help scroll.txt`. There are still some deviations from the origial behavior,
which hopefully will be addressed in the future:

* `^D`, `^U`, `^F`, `^B` should beep when they can't move any further.
* `^F` and `^B` should respect the `window` option.
* Native commands may move in a smarter way over wrapped/folded lines.


Credits
-------

Created by [Piotr Śliwka](https://github.com/psliwka).

Many thanks to authors of [vim-smooth-scroll], [comfortable-motion.vim], and
[sexy_scroller.vim] for inspiration!

License
-------

[MIT](LICENSE)

[vim-plug]: https://github.com/junegunn/vim-plug
[vim-smooth-scroll]: https://github.com/terryma/vim-smooth-scroll
[comfortable-motion.vim]: https://github.com/yuttie/comfortable-motion.vim
[sexy_scroller.vim]: https://github.com/joeytwiddle/sexy_scroller.vim
