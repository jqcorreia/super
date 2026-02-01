package platform

ortho :: proc(l: f32, r: f32, b: f32, t: f32) -> [16]f32 {
	return [16]f32 {
		2.0 / (r - l),
		0.0,
		0.0,
		0.0,
		0.0,
		2.0 / (t - b),
		0.0,
		0.0,
		0.0,
		0.0,
		-1.0,
		0.0,
		-(r + l) / (r - l),
		-(t + b) / (t - b),
		0.0,
		1.0,
	}
}
