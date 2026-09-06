# r_view

Mac OS app to view images and pick colors out of them.

The point of this program is to show you an image without changing it. It never
smooths, never interpolates, and never converts colors into your display's
profile, so the number it reports for a pixel is the number in the file.

```sh
% r_view foo.png
```

![The r_view icon](icon/r_view.png)

# Usage

Each file on the command line opens in its own window, sized to fit the image:

```sh
% r_view foo.png bar.jpg
```

Run it with no arguments, or use <kbd>&#x2318;O</kbd> (File > Open), to pick
files with a dialog. File > Open Recent lists what you've opened before. <kbd>&#x2318;V</kbd> (Edit > Paste) opens the image on the
clipboard in a window named "Clipboard".

## Picking colors

Hold the mouse button down over the image. The pixel under the pointer is shown
in the title bar:

    foo.png – zoom 1:2 – (10,20) → (10,20,30,40) #0A141E28

That's the pixel's position in the image (not in the window), its color as
decimal RGBA, and the same color as a CSS hex string. Alpha is left out of both
when the pixel is opaque, so most images read as plain RGB:

    foo.png – (10,20) → (10,20,30) #0A141E

<kbd>&#x2318;C</kbd> (Edit > Copy Color) copies the hex without the `#`, ready to
paste into code: `0A141E28`, or `0A141E` if the pixel is opaque.

Releasing the button, or moving off the image, leaves the last reading in the
title bar so you can go read it.

## Zooming

<kbd>&#x2318;+</kbd> and <kbd>&#x2318;&minus;</kbd> (View > Zoom In and Zoom Out)
change the zoom, by powers of two only, from 1:16 to 16:1. The zoom appears in
the title bar whenever it isn't 1:1. <kbd>&#x2318;0</kbd> (View > Actual Size)
goes back to 1:1, and <kbd>&#x2318;9</kbd> (View > Zoom to Fit) picks the
largest zoom that shows the whole image in the window. Zoom to Fit scales small
images up as well as large ones down, and is the one zoom command that leaves
the window exactly as it is, since it's fitting the image to the window you
already have.

Zooming in never smooths: at 4:1 each image pixel is a hard-edged 4-by-4 block,
so no color reaches the screen that isn't in the file. Zooming out has to combine
pixels, and averages each block rather than dropping all but one of them, which
would alias badly. The color picker reads the original image either way, so the
color in the title bar is always a real pixel of the file rather than an average
of several — zoomed out, the pixel you're told about and the pixel you're looking
at won't be quite the same color.

An image opens at 1:1 if it fits on the screen, and otherwise zoomed out by
powers of two until it does. Zooming in grows the window to fit the larger image,
up to the size of the screen; zooming out leaves the window where you put it.
When the image is bigger than the window, pan with two fingers or the scrollbars.

## Background

Semi-transparent images are drawn over a background, which you choose in View >
Background: a checkerboard (the default), black, gray, or white. The menu is
grayed out for an image with no transparent pixels, since there'd be nothing for
the background to show through. The area of the window outside the image is
always #929292, so you can tell it from the image.

# Installing

```sh
% make install
```

That builds the app and installs two things:

- `~/Applications/r_view.app`, the app itself, which you can also launch from
  the Finder or Spotlight.
- `~/.local/bin/r_view`, a small script that runs it, so that `r_view foo.png`
  works from any shell. Make sure `~/.local/bin` is on your `PATH`.

Override the destinations to install machine-wide:

```sh
% make install PREFIX=/usr/local APPDIR=/Applications
```

`make uninstall` removes both, and takes the same variables.

# Building

Run `make`. You'll find the app in `build/mac-arm64/r_view.app`.

Run `make check` to typecheck and run the tests, and `make run FILE=foo.png` to
run without packaging.

`icon/r_view.icns` is committed, and `make app` uses it as-is rather than
regenerating it, so building never depends on opening a window. After changing
`icon/draw-icon.ts`, run `make icon` and commit the new `.icns`.

# Formats

PNG, JPEG, GIF, WebP, AVIF, BMP and ICO, which is what Chromium can decode. The
file's own bytes decide, so a mislabeled extension still opens.

# Notes on fidelity

Two things this program does differently from an ordinary image viewer, both so
that the color it reports is the color in the file:

- It decodes with WebCodecs rather than drawing into a canvas and reading it
  back. A canvas stores colors premultiplied by alpha, and the round trip shifts
  every semi-transparent pixel: a pixel written as `(32,128,80,36)` comes back
  as `(35,128,78,36)`, and a fully transparent pixel loses its color entirely.
  WebCodecs hands back the bytes the file actually contains. (The canvas is
  still the fallback for anything WebCodecs won't decode, where it's exact
  anyway, since those formats have no alpha.)
- It turns off color management, both when decoding and when drawing. An image
  with an embedded profile will therefore look slightly different here than in
  Preview — this program shows you the numbers, not the intent.

Scaling is done by hand, a pixel at a time, rather than by `drawImage`. Every
zoom is a power of two and the device pixel ratio is a whole number, so an image
pixel either fills a whole block of device pixels or a whole block of image
pixels averages down to one. Shrinking happens first, in a separate pass, which
keeps drawing to a plain block copy and keeps the checkerboard behind a
transparent image from being blurred along with it. The canvas is also kept on
whole device pixels while scrolling: at a fractional position the compositor
would resample it, which is exactly the blurring this program exists to avoid.

On a retina display, 1:2 needs no averaging at all — each image pixel still gets
a device pixel of its own, so you're seeing the file at your display's full
resolution.

# Source layout

- `src/core/` — the zoom ladder, the title format, the averaging that shrinks an
  image, and the compositor that turns image pixels into screen pixels. Plain TypeScript with no dependency on
  Electron, and where nearly all the behavior described above lives. This is
  what the tests in `test/` cover.
- `src/main/` — the Electron main process: the command line, the windows, and
  the menu. It owns the zoom and the background, since it needs both to size
  windows and to check the right menu items.
- `src/renderer/` — decodes the image and draws it.
- `icon/` — draws the app icon and packages it as an `.icns`.

# License

Copyright &copy; Lawrence Kesteloot, [MIT license](LICENSE).
