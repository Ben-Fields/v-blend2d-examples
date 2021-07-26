module main

import blend2d

[console]
fn main() {
	println('Begin example.')

	img := blend2d.new_image(480, 480) ?

	// Attach a rendering context into `img`.
	ctx := blend2d.new_context(img) ?

	// Clear the image.
	ctx.set_comp_op(.src_copy)
	ctx.fill_all()

	// Create font face.
	face := blend2d.new_font_face('NotoSans-Regular.ttf') or {
		println('Failed to load a font-face')
		return
	}

	// Create font from the font face.
	font := blend2d.new_font(face, 50.0)

	// Draw some strings. (As a reminder, strings in V are encoded as UTF-8).
	ctx.set_fill_color(blend2d.rgb_hex(0xFFFFFF))
	ctx.fill_string(60, 80, font, 'Hello Blend2D!')
	ctx.rotate_origin(0.785398)
	ctx.fill_string(250, 80, font, 'Rotated Text')

	// Detach the rendering context from `img`.
	ctx.end()

	// Write the result using a codec provided by Blend2D.
	codec := blend2d.new_codec_by_name('BMP') ?
	img.write_to_file('blend2d-output.bmp', codec) or {
		println(err)
		return
	}

	println('End example.')
}
