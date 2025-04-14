package engine

import "core:c"
import "core:fmt"
import "core:os/os2"
import "core:strings"

foreign import sft "system:libschrift.a"


@(default_calling_convention = "c", link_prefix = "sft_")
foreign sft {
	loadfile :: proc(filename: cstring) -> ^SFT_Font ---
	lookup :: proc(font: ^SFT, ch: c.char, glyph: ^SFT_Glyph) ---
	gmetrics :: proc(font: ^SFT, glyph: SFT_Glyph, metrics: ^SFT_GMetrics) ---
	render :: proc(font: ^SFT, glyph: SFT_Glyph, image: SFT_Image) ---
}

// struct SFT
// {
// 	SFT_Font *font;
// 	double    xScale;
// 	double    yScale;
// 	double    xOffset;
// 	double    yOffset;
// 	int       flags;
// };

// struct SFT_Font
// {
// 	const uint8_t *memory;
// 	uint_fast32_t  size;
// #if defined(_WIN32)
// 	HANDLE         mapping;
// #endif
// 	int            source;

// 	uint_least16_t unitsPerEm;
// 	int_least16_t  locaFormat;
// 	uint_least16_t numLongHmtx;
// };

SFT :: struct {
	font:    ^SFT_Font,
	xScale:  c.double,
	yScale:  c.double,
	xOffset: c.double,
	yOffset: c.double,
	flags:   c.int,
}

SFT_Font :: struct {
}
SFT_Glyph :: c.uint32_t

SFT_GMetrics :: struct {
	advanceWidth:    c.double,
	leftSideBearing: c.double,
	yOffset:         c.int,
	minWidth:        c.int,
	minHeight:       c.int,
}

SFT_Image :: struct {
	pixels: rawptr,
	width:  c.int,
	height: c.int,
}

SFT_DOWNWARD_Y :: 0x01


load_font :: proc(filename: string, size: f64) -> SFT {
	font: ^SFT_Font
	font = loadfile(strings.clone_to_cstring(filename))
	if (font == nil) {
		panic("Failed to load font")
	}
	sft: SFT
	sft.font = font
	sft.xScale = size
	sft.yScale = size
	sft.xOffset = 0.0
	sft.yOffset = 0.0
	sft.flags = SFT_DOWNWARD_Y

	return sft
}

// let mut file_map: HashMap<String, String> = HashMap::new();
// let fc_list = Command::new("fc-list").output();

// for line in String::from_utf8(fc_list.unwrap().stdout).unwrap().lines() {
//     if !line.contains("style=Regular") {
//         continue;
//     }
//     let split = line.split(":").collect::<Vec<&str>>();
//     let path = split.first().unwrap();
//     let family_names = split.get(1).unwrap();
//     for family in family_names.split(",") {
//         file_map.insert(family.trim().to_string(), path.to_string());
//     }
// }
// FontManager {
//     file_map,
//     ttf,
//     cache: HashMap::new().into(),
// }

get_font_map :: proc() -> map[string]string {
	fonts := make(map[string]string)

	_, out, _, _ := os2.process_exec({command = {"fc-list"}}, context.allocator)

	for line, i in strings.split(string(out), "\n") {
		if strings.contains(line, "style=Regular") {
			continue
		}

		split := strings.split(line, ":")
		path := split[0]

		// Guard against odd lines
		if len(split) < 2 {
			continue
		}

		family_names := split[1]
		for fname in strings.split(family_names, ",") {
			fonts[strings.trim_left(fname, " ")] = path
		}
	}

	return fonts
}
