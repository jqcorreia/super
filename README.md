# super
Press &lt;super> to do stuff!

## Build Instructions

```
git submodule init`
git submodule update`
odin build -
./super
```

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
- [ ] Implement list selected item/index mechanics - !
- [x] Image (PNG, JPEG) rendering
- [ ] Layout manager, dumb, simple one, please...
- [ ] Keyboard repeat 
- [ ] Mouse input
- [ ] Multiple canvas support. Dunno why no work...
- [ ] Window/Surface resize, push EGL creation to configure()
- [ ] BIG GOAL: Make it as usable as `tudo` so I can daily drive this

! == ongoing
