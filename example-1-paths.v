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

	// Fill some path.
	path := blend2d.new_path()
	path.move_to(26, 31)
	path.cubic_to(642, 132, 587, -136, 25, 464)
	path.cubic_to(882, 404, 144, 267, 27, 31)

	ctx.set_comp_op(.src_over)
	ctx.set_fill_style(blend2d.new_rgba32(0xFFFFFFFF))
	ctx.fill_path(path)

	// Detach the rendering context from `img`.
	ctx.end()

	// Let's use some built-in codecs provided by Blend2D.
	codec := blend2d.new_codec_by_name('BMP') ?
	img.write_to_file('blend2d-output.bmp', codec) or {
		println('Failed to write output. $err')
		return
	}

	println('End example.')
}
