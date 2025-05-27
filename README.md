# super
Press &lt;super> to do stuff!

## Build Instructions
```
git submodule init`
git submodule update`
odin build -
./super
```

## Dependencies
- `libschrift` - font rendering 
- `resvg` - svg rendering 
- `libwayland` - wayland support
- `libxkbcomp` - keyboard state handling (some day we will remove this)

## Devlog
- [x] working layer and window surfaces
- [x] semblance of an engine with abstracted canvas creation
- [x] rudimentary shader map
- [x] keyboard input 
- [x] keyboard event controller 
- [x] keyboard with deadkeys and keyboard state
- [x] Font manager (fc-list based)
- [x] Primitive text rendering (libschrift based)
- [x] Use proper font metrics based on previous glyph (leftSideBearing et al)
- [x] fix WAYLAND_DEBUG crashing (prolly wayland-odin's fault)
- [x] Basic label widget
- [x] make state global ffs
- [x] organize shaders
- [x] Widgets! Kinda
- [x] Scrollable lists
- [x] Proper text rendering with glyph caching
- [x] Rudimentary text box input
- [x] Fix error where number of list items is too small.
- [x] Implement applications source 
- [x] Implement secrets source
- [x] Add clipboard support (used wl-copy)
- [x] Fix list flickering and weird alpha (disabled blend toggling)
- [x] Fix window layer - fixed, and setup max and min sized, now it's proper modal
- [x] Investigate modal vs layer
- [x] Image (PNG, JPEG) rendering
- [x] Image (SVG) rendering
- [x] BIG GOAL: Make it as usable as `tudo` so I can daily drive this
- [x] Load correct sized icons with load hints
- [x] Keyboard repeat (some edge cases may not work, but it's usable) 
- [ ] Vendor some assets like default font
- [ ] Layout manager, dumb, simple one, please... - !
- [ ] Implement list selected item/index mechanics - !
- [ ] Make a UI package properly usable
- [ ] Check why egl.CreateContext() allocates so much memory! 
- [ ] Mouse input
- [ ] Multiple canvas support. Dunno why no work...
- [ ] Window/Surface resize, push EGL creation to configure()
- [ ] Port platform and renderer to Vulkan

! == ongoing
