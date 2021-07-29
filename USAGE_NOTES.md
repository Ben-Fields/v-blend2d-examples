Usage notes for the V wrapper of the Blend2D library

### For the `ui-example-...` examples:

- `window` cannot be declared in the initialization of `app` because that causes a 
	comptime unhandled exception. Attributes are likely not evaluated in order.
- After the ui functions are called, member variables are not set yet. You must
	use the `on_init` function of `window` to use post-initialized values.
- By default, the canvas `draw_fn()` only draws on input events, so one must call 
	`window.refresh()`. To disable this behavior, you must set `gg.Context.ui_mode`
	to false (which the `ui` module enables by default). You must then implement 
	frame culling yourself if desired. `ui_mode` of the gg module does not support 
	partial frame culling. Notice that at least a cached version of the image is 
	drawn every frame or else the `ui` library will overwrite it.
- The height of the checkbox cannot be set. Not implemented in v/ui yet.
