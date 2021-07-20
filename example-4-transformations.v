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

	// Read an image from file.
	texture := blend2d.read_from_file('texture.jpeg') or {
		println('Failed to load a texture. $err')
		return
	}

	// Rotate by 45 degrees about a point at [240, 240].
	ctx.rotate(0.785398, 240.0, 240.0)

	// Create a pattern and use it to fill a rounded rectangle.
	pattern := blend2d.new_pattern(texture, extend: .repeat) ?
	ctx.set_fill_pattern(pattern)
	ctx.set_comp_op(.src_over)
	ctx.fill_round_rect(50.0, 50.0, 380.0, 380.0, 80.5)

	// Detach the rendering context from `img`.
	ctx.end()

	// Write the result using a codec provided by Blend2D.
	codec := blend2d.new_codec_by_name('BMP') ?
	img.write_to_file('blend2d-output.bmp', codec) or {
		println('Failed to write output. $err')
		return
	}

	println('End example.')
}



  

