module main

import blend2d

[console]
fn main() {
	println('Begin example.')

	img := blend2d.new_image(480, 480)?

	// Attach a rendering context into `img`.
	ctx := blend2d.new_context(img)?

	// Clear the image.
	ctx.set_comp_op(.src_copy)
	ctx.fill_all()

	// Create font face.
	face := blend2d.new_font_face('NotoSans-Regular.ttf') or {
		println('Failed to load a font-face. $err')
		return
	}

	// Create font from the font face.
	font := blend2d.new_font(face, 20.0)

	// ctx.set_fill_color(blend2d.new_rgba32(0xFFFFFFFF))

	//metrics = font.metrics()
	//tm TextMetrics
	//gb GlyphBuffer

	// BLPoint p(20, 190 + fm.ascent);
	// const char* text = "Hello Blend2D!\n"
	// 				   "I'm a simple multiline text example\n"
	// 				   "that uses BLGlyphBuffer and fillGlyphRun!";
	// for (;;) {
	// 	const char* end = strchr(text, '\n');
	// 	gb.setUtf8Text(text, end ? (size_t)(end - text) : SIZE_MAX);
	// 	font.shape(gb);
	// 	font.getTextMetrics(gb, tm);

	// 	p.x = (480.0 - (tm.boundingBox.x1 - tm.boundingBox.x0)) / 2.0;
	// 	ctx.fillGlyphRun(p, font, gb.glyphRun());
	// 	p.y += fm.ascent + fm.descent + fm.lineGap;

	// 	if (!end) break;
	// 	text = end + 1;
	// }

	// TODO
	ctx.set_fill_color(blend2d.new_rgba32(0xFFFFFFFF))
	ctx.fill_string(20, 80, font, 'Drawing V "Runes" (Blend2D "Glyphs")')
	ctx.fill_string(20, 100, font, 'not yet implemented.')

	// Detach the rendering context from `img`.
	ctx.end()

	// Let's use some built-in codecs provided by Blend2D.
	codec := blend2d.new_codec_by_name('BMP')?
	img.write_to_file('blend2d-output.bmp', codec) or {
		println(err)
		return
	}

	println('End example.')
}
