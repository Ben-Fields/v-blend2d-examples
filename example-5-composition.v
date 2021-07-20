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

	// First shape filled by a radial gradient.
	radial := blend2d.new_radial_gradient(180, 180, 180, 180, 180, extend: .pad)
	radial.add_stop(0.0, blend2d.new_rgba32(0xFFFFFFFF))
	radial.add_stop(1.0, blend2d.new_rgba32(0xFFFF6F3F))

	ctx.set_comp_op(.src_over)
	ctx.set_fill_gradient(radial)
	ctx.fill_circle(180, 180, 160)

	// Second shape filled by a linear gradient.
	linear := blend2d.new_linear_gradient(195, 195, 470, 470, extend: .pad)
	linear.add_stop(0.0, blend2d.new_rgba32(0xFFFFFFFF))
	linear.add_stop(1.0, blend2d.new_rgba32(0xFF3F9FFF))

	ctx.set_comp_op(.difference)
	ctx.set_fill_gradient(linear)
	ctx.fill_round_rect(195, 195, 270, 270, 25)

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
