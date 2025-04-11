package xkbcommon

import "core:c"
import "vendor:x11/xlib"

foreign import xkb "system:xkbcommon"

@(default_calling_convention = "c", link_prefix = "xkb_")
foreign xkb {
	context_new :: proc(flags: u32) -> ^xkb_context ---
	keymap_new_from_string :: proc(ctx: ^xkb_context, str: cstring, format: keymap_format, compile_flags: keymap_compile_flags) -> ^xkb_keymap ---
	state_new :: proc(keymap: ^xkb_keymap) -> ^xkb_state ---
	state_key_get_one_sym :: proc(state: ^xkb_state, key: c.uint32_t) -> xlib.KeySym ---
	state_key_get_utf8 :: proc(state: ^xkb_state, key: c.uint32_t, buffer: cstring, size: c.size_t) ---
}


// struct xkb_context {
//     int refcnt;

//     ATTR_PRINTF(3, 0) void (*log_fn)(struct xkb_context *ctx,
//                                      enum xkb_log_level level,
//                                      const char *fmt, va_list args);
//     enum xkb_log_level log_level;
//     int log_verbosity;
//     void *user_data;

//     struct xkb_rule_names names_dflt;

//     darray(char *) includes;
//     darray(char *) failed_includes;

//     struct atom_table *atom_table;

//     /* Used and allocated by xkbcommon-x11, free()d with the context. */
//     void *x11_atom_cache;

//     /* Buffer for the *Text() functions. */
//     char text_buffer[2048];
//     size_t text_next;

//     unsigned int use_environment_names : 1;
//     unsigned int use_secure_getenv : 1;
// };

xkb_context :: struct {}
xkb_keymap :: struct {}
xkb_state :: struct {}

keymap_format :: enum u32 {
	XKB_KEYMAP_FORMAT_TEXT_V1 = 1,
}

keymap_compile_flags :: enum u32 {
	XKB_KEYMAP_COMPILE_NO_FLAGS = 0,
}
