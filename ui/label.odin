package ui

import cv "../platform/canvas"
import "../platform/fonts"

Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
	font: ^fonts.Font,
}

label_draw :: proc(label: Label, canvas: ^cv.Canvas) {
	cv.draw_text(canvas, label.x, label.y, label.text, label.font)
}
