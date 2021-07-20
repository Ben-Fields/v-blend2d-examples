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

	// Apply stroke styling to a path.
	linear := blend2d.new_linear_gradient(0, 0, 0, 480, extend: .pad)
	linear.add_stop(0.0, blend2d.new_rgba32(0xFFFFFFFF))
	linear.add_stop(1.0, blend2d.new_rgba32(0xFF1F7FFF))

	path := blend2d.new_path()
	path.move_to(119, 49)
	path.cubic_to(259, 29, 99, 279, 275, 267)
	path.cubic_to(537, 245, 300, -170, 274, 430)

	ctx.set_comp_op(.src_over)
	ctx.set_stroke_gradient(linear)
	ctx.set_stroke_width(15)
	ctx.set_stroke_cap_start(.round)
	ctx.set_stroke_cap_end(.butt)
	ctx.stroke_path(path)

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
