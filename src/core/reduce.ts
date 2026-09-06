// Shrinking an image before it's drawn.
//
// Zooming in is a block copy, so it invents no colors. Zooming out has to throw
// pixels away, and keeping one pixel out of every k is what produces the harsh
// aliasing you see when a detailed image is shrunk. Averaging each block
// instead gives a result worth looking at.
//
// The color picker reads the original image, not this one, so the color in the
// title bar is always a color that's really in the file.

import { type SourceImage } from "./compose.js";
import { zoomScale } from "./zoom.js";

// How many image pixels fall into each device pixel, as a power of two. It's 1
// whenever the image is drawn at or above the resolution of the display, in
// which case no pixel is being dropped and there's nothing to average. On a
// retina display that covers 1:2 as well as every zoom in: at 1:2 each image
// pixel still gets its own device pixel.
export function reductionFor(zoom: number, dpr: number): number {
    const scale = zoomScale(zoom)*dpr;
    return scale >= 1 ? 1 : Math.round(1/scale);
}

// Average each factor-by-factor block of pixels down to one. Blocks along the
// right and bottom edges can be partial, and average only the pixels present.
//
// Averaging happens on the stored sRGB values rather than in linear light. That
// isn't what a physicist would do, but it is what Preview, Photoshop and every
// browser do, and an image here should shrink the way it does everywhere else.
export function reduce(image: SourceImage, factor: number): SourceImage {
    if (factor <= 1) {
        return image;
    }

    const width = Math.ceil(image.width/factor);
    const height = Math.ceil(image.height/factor);
    const data = new Uint8ClampedArray(width*height*4);

    for (let y = 0; y < height; y++) {
        const top = y*factor;
        const bottom = Math.min(top + factor, image.height);

        for (let x = 0; x < width; x++) {
            const left = x*factor;
            const right = Math.min(left + factor, image.width);

            // Color is weighted by alpha, so that the color of a transparent
            // pixel -- which nobody can see, and which some formats don't even
            // define -- doesn't bleed into its neighbors.
            let red = 0;
            let green = 0;
            let blue = 0;
            let alpha = 0;

            for (let sourceY = top; sourceY < bottom; sourceY++) {
                let i = (sourceY*image.width + left)*4;
                for (let sourceX = left; sourceX < right; sourceX++, i += 4) {
                    const pixelAlpha = image.data[i + 3]!;
                    red += image.data[i]!*pixelAlpha;
                    green += image.data[i + 1]!*pixelAlpha;
                    blue += image.data[i + 2]!*pixelAlpha;
                    alpha += pixelAlpha;
                }
            }

            // A block of entirely transparent pixels stays transparent black.
            if (alpha > 0) {
                const destination = (y*width + x)*4;
                data[destination] = Math.round(red/alpha);
                data[destination + 1] = Math.round(green/alpha);
                data[destination + 2] = Math.round(blue/alpha);
                data[destination + 3] = Math.round(alpha/((right - left)*(bottom - top)));
            }
        }
    }

    return { width, height, data };
}
