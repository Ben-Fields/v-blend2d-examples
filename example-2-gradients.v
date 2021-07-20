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

	// Coordinates can be specified now or changed later.
	linear := blend2d.new_linear_gradient(0, 0, 0, 480)

	// Color stops can be added in any order.
	linear.add_stop(0.0, blend2d.new_rgba32(0xFFFFFFFF))
	linear.add_stop(0.5, blend2d.new_rgba32(0xFF5FAFDF))
	linear.add_stop(1.0, blend2d.new_rgba32(0xFF2F5FDF))

	// Fill and draw a shape.
	ctx.set_fill_gradient(linear)
	ctx.set_comp_op(.src_over)
	ctx.fill_round_rect(40.0, 40.0, 400.0, 400.0, 45.5)

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
