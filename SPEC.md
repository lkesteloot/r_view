
This is an image viewer called `r_view`. Its job is to show images with as little
distortion as possible, and inspect them. The main use is to pick colors from images.

The tool will take zero or more image files on the command line and open a window for
each. File > Open will do the expected thing, along with the other window operations
(close etc). There is no image modification or saving.

The tool supports zooming (Command + and -), but only by powers of two relative
to the original image. Zooms go from 1:16 to 16:1. When opening an image, the
window will match the size of the image, unless that won't fit (window border + image
is smaller than the screen), in which case the image will be zoomed out (again by
powers of two) until it fits. If the zoom is not 1:1, it will be displayed in the
title bar, to the right of the filename ("foo.jpg - zoom 1:2"). 1:2 means zoomed
out once from actual res, and 2:1 means zoomed in (each image pixel takes 2x2
on the screen). When zoomed out, there should be no smoothing (i.e., the 2x2
square should entirely be the original pixel). There is no animation when
changing zoom, it should happen instantly.

When the mouse button is down, the hovered pixel's color will be displayed in
the title bar, to the right of zoom. The format will be:
`foo.png - zoom 1:2 - (x,y) -> (10,20,30,40) #0A141E28` where x and y are the
pixel location in the image (not in the window), the four numbers are decimal
RGBA, and the hex is the CSS hex RGBA. Leave out alpha completely from both
if it's 255. Command-C should copy the hex of the color without the hash symbol,
like "0A141E28" or "0A141E" if opaque. The Edit menu item should be "Copy Color".
When zoomed out more than 1:1, any image pixel is fine to use (just be
consistent, like the upper-left of the square), no need to average. If the mouse
moves outside the image area, or the user releases the button, leave the title
where a pixel was last sampled.

Semi-transparent images should be drawn over a background color. This background
is configurable in the View menu, in a Background submenu. The options are
checkerboard (the default, white and #CCCCCC, 8x8 pixels in screen space),
black, gray (#808080), and white.

If the window is larger than the zoomed image, the area outside the image should
be a solid #929292.

If Edit > Paste is selected, and the clipboard has an image, a new window should
open with that image and the name "Clipboard".

Implementation-wise, this will be in TypeScript using Electron. There will be a
Makefile to build and install the program. A README.md should tell the user how
to use the program. See ~/mine/plotter2 for a good example (license, Makefile,
tech used, etc).

