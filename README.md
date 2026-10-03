# AeroSpace: configurable width for a lone tiled window

This is my working AeroSpace build for my Mac Studio and laptop. When a workspace
has one tiled window, it centres that window at a configurable percentage of the
current monitor's usable width. The percentage can change with monitor width, so
the same configuration works across my displays.

![Illustration of a lone tiled window centred at 50% width on a standard 16:9 monitor](docs/assets/single-window-width.svg)

*Illustration of the 50% rule on a standard monitor; this is not an app screenshot.*

I am sharing the code as a working solution and proof of concept for
[upstream discussion #2308](https://github.com/nikitabobko/AeroSpace/discussions/2308).
This is not an official AeroSpace release or a fork I plan to maintain
separately. For the standard application, documentation, and installation
instructions, see [upstream AeroSpace](https://github.com/nikitabobko/AeroSpace).

## What this branch changes

The branch adapts the single-window and accordion aspect-ratio work in
[PR #2093](https://github.com/nikitabobko/AeroSpace/pull/2093) to the newer
AeroSpace code, then adds `single-window-width-rules`. Each rule sets the width
of a lone tiled window as a percentage of usable monitor width when the monitor
meets a minimum width in macOS scaled display points. The highest matching
threshold wins. If no width rule matches, the window keeps its usual width
unless an aspect-ratio setting also applies.

My configuration in `~/.aerospace.toml` is:

```toml
single-window-width-rules = [
  { min-monitor-width = 0, width-percent = 66 },
  { min-monitor-width = 2000, width-percent = 50 },
]
apply-aspect-to-accordion = 'none'
```

This gives the laptop's 1512-point display a 66%-width lone window and the
Studio's 2560-point displays a 50%-width lone window. The optional PR #2093
sizing of an accordion (a stack of overlapping windows) is disabled here, so
multiple tiled windows use the normal layout. AeroSpace full screen still
fills the display. The width rules can be edited for other monitors and setups.

The [width-rules commit](https://github.com/JasonBates/AeroSpace-single-window-width/commit/92be41f)
shows the additional implementation and tests.
