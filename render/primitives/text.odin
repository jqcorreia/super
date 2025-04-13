package primitives

import "../../engine/"
import "core:fmt"

// SFT_Glyphglyph
// SFT_GMetricsmetrics
// sft_lookup(font, text[i], &glyph)

draw_text :: proc(text: string, x: u32, y: u32, state: ^engine.State) {
	font := state.font
	glyph := new(engine.SFT_Glyph)
	metrics := new(engine.SFT_GMetrics)
	for i in 0 ..< len(text) {
		fmt.println(font, text[i], glyph)
		engine.lookup(&font, 'a', glyph)
		fmt.println(glyph)
		engine.gmetrics(glyph^, metrics)
		fmt.println(metrics)
	}

}
