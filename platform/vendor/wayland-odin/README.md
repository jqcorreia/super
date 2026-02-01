# wayland-odin

## Usage
Vendor the `wayland` folder into your project and add the following to your `odin` file:

```odin
import wl "wayland"

```
Nothing else, pretty standard.

You can also submodule it and import it with
```odin
import wl "wayland-odin/wayland"
```

If you want to use the scanner, you can do so by running the following command:

```bash
odin run wayland -i <xml-input-file> -o <output-file>
```
The code will be generated with `package wayland` at the header. PR are accepted to do it otherwise.

## Devlog
- [x] Port just enough to call wl_display_get_registry and receive the globals list
- [x] Usable wayland-scanner that ports code to odin.
- [x] Write obligatory cornflower blue example
- [x] Solve shm file allocation bug that makes Hyprland crap its pants
- [x] Generate _destroy methods that don't collide with interface 'destroy' methods, check C scanner for this
- [x] Fix WAYLAND_DEBUG=1 crash
- [ ] Implement server side generation.
- [ ] Generate more ergonomic code maybe without cdecl procs
- [ ] Have quality enough to submit as vendor
- [ ] Do not depend on libwayland (if this goes in a really awesome fashion)
