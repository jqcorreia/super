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
	compose_table_new_from_locale :: proc(ctx: ^xkb_context, locale: cstring, flags: u32) -> ^xkb_compose_table ---
	compose_state_new :: proc(table: ^xkb_compose_table, flags: u32) -> ^xkb_compose_state ---
	compose_state_feed :: proc(state: ^xkb_compose_state, key_sym: u32) -> xkb_compose_feed_result ---
	compose_state_get_status :: proc(state: ^xkb_compose_state) -> xkb_compose_status ---
	compose_state_get_utf8 :: proc(state: ^xkb_compose_state, buffer: cstring, size: c.size_t) -> c.int ---
}

// compose_table := xkb_compose_table_new_from_locale(context, "pt_BR.UTF-8", 0)
// compose_state := xkb_compose_state_new(compose_table, 0)

xkb_context :: struct {
}
xkb_keymap :: struct {
}
xkb_state :: struct {
}

xkb_compose_table :: struct {
}

xkb_compose_state :: struct {
}

keymap_format :: enum u32 {
	XKB_KEYMAP_FORMAT_TEXT_V1 = 1,
}

keymap_compile_flags :: enum u32 {
	XKB_KEYMAP_COMPILE_NO_FLAGS = 0,
}

xkb_compose_feed_result :: enum u32 {
	XKB_COMPOSE_FEED_IGNORED  = 0,
	XKB_COMPOSE_FEED_ACCEPTED = 1,
}
xkb_compose_status :: enum {
	/** The initial state; no sequence has started yet. */
	XKB_COMPOSE_NOTHING,
	/** In the middle of a sequence. */
	XKB_COMPOSE_COMPOSING,
	/** A complete sequence has been matched. */
	XKB_COMPOSE_COMPOSED,
	/** The last sequence was cancelled due to an unmatched keysym. */
	XKB_COMPOSE_CANCELLED,
}
