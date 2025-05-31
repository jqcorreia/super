package ui
import "../types"

import "core:math"

Background :: struct {
	color:  ^types.Color,
	image:  string,
	shader: string,
}

Theme :: struct {
	input_text_color:   types.Color,
	input_border_color: types.Color,
	list_selected:      types.Color,
	background:         Background,
}

default_theme := Theme {
	input_border_color = {0.5, 0.5, 0.5, 1.0},
	background = {shader = "Singularity"},
	input_text_color = {1.0, 1.0, 1.0, 1.0},
}

other_theme := Theme {
	input_border_color = {0.2, 0.2, 0.9, 1.0},
	input_text_color = {0.2, 0.2, 0.9, 1.0},
	background = {color = &{0.3, 0.3, 0.3, 1.0}},
}

current_theme := default_theme

color_lerp :: proc(old: ^types.Color, new: ^types.Color, t: f32) -> types.Color {
	// This is kinda stupid, need a better way to do it, just return the new color
	// x := math.lerp(old.x, new.x, t)
	// y := math.lerp(old.y, new.y, t)
	// z := math.lerp(old.z, new.z, t)
	// w := math.lerp(old.w, new.w, t)
	return new^
}

change_theme :: proc() {
	theme := Theme {
		// input_border_color = color_lerp(
		// 	&current_theme.input_border_color,
		// 	&other_theme.input_border_color,
		// 	0.2,
		// ),
		input_border_color = other_theme.input_border_color,
		input_text_color   = other_theme.input_text_color,
		background         = other_theme.background,
	}
	current_theme = theme
}
