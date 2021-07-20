# Blend2D Examples in V

## About

This is not a V module; rather, a collection of examples for the [Blend2D library in V](https://github.com/Ben-Fields/v-blend2d).

Clone this repository, and with the `blend2d` module installed, run any example with `v run <example name>`.

## Attribution

The `example-...` and `ui-example-...` files are adapted directly from [Petr Kobalicek's Blend2D examples](https://github.com/blend2d/blend2d-samples).

The ui examples are adapted to use V's ui module instead of QT.

The `gg-example-...` files are written by Ben Fields.

## Notes

For now, V distinguishes between console and graphical apps.
Until this is fixed, you must put `[console]` before `main()` to ensure your
`println()` staements are correctly outputted.
The effect may not be apparent unless you run the program on Windows.

https://github.com/vlang/v/issues/8800
