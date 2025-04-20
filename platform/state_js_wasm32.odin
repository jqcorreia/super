package platform

PlatformState :: struct {
	shaders: Shaders,
	// xkb:     Xkb,
	input:   ^Input,
}

init_platform :: proc() -> ^PlatformState {
	state := new(PlatformState)

	// Initialize shaders controller
	state.shaders = create_shaders_controller()
	return state
}
