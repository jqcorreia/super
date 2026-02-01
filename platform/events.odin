package platform

Event :: union {
	KeyPressed,
	KeyReleased,
	TextInput,
	MouseMove,
	MouseButton,
	MouseWheel,
	WindowResize,
}

WindowResize :: struct {
	new_width:  i32,
	new_height: i32,
}
KeyPressed :: struct {
	key:       KeySym,
	keycode:   u32,
	serial:    u32,
	modifiers: bit_set[Modifiers],
}

KeyReleased :: struct {
	key:    KeySym,
	serial: u32,
}

TextInput :: struct {
	text: string,
}

MouseMove :: struct {
	x: i32,
	y: i32,
}

MouseButton :: struct {
	button: MouseButtonId,
	state:  MouseButtonState,
}

MouseWheel :: struct {
	axis:      MouseWheelAxis,
	direction: i8, // -1 if up, 1 if down
}

MouseWheelAxis :: enum {
	Vertical,
	Horizontal,
}

// This is coming from linux kernel's linux/input-event-codes.h header file
MouseButtonId :: enum u32 {
	LEFT   = 272,
	RIGHT  = 273,
	MIDDLE = 274,
}

MouseButtonState :: enum u32 {
	RELEASED = 0,
	PRESSED  = 1,
}

Modifiers :: enum u32 {
	Shift = 1,
	Ctrl  = 4,
	Alt   = 8,
	Super = 64,
}
