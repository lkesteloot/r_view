// Turns the image into the exact pixels that go on the screen.
//
// We do the scaling here instead of handing the image to drawImage() because
// this program's whole job is to not distort the image. Every zoom is a power
// of two and the device pixel ratio is an integer, so one image pixel always
// fills a whole k-by-k block of device pixels: a block copy, with no filtering
// and no color that wasn't in the image. Shrinking, where pixels genuinely have
// to be combined, happens beforehand in reduce.ts.
//
// Coordinates here are device pixels unless they say "point". The image's
// top-left corner sits at (originX, originY), which is negative when the image
// is scrolled.

import {
    type Background, CHECKER_DARK, CHECKER_LIGHT, CHECKER_SIZE, type Rgb, solidColor, SURROUND,
} from "./background.js";
import { type Size, zoomScale } from "./zoom.js";

export interface SourceImage {
    readonly width: number;
    readonly height: number;
    // RGBA, one byte per channel, not premultiplied.
    readonly data: Uint8ClampedArray;
}

// Whether any pixel is less than fully opaque. The background only shows
// through such an image, so View > Background is grayed out without one.
export function hasTransparency(image: SourceImage): boolean {
    for (let i = 3; i < image.data.length; i += 4) {
        if (image.data[i] !== 255) {
            return true;
        }
    }
    return false;
}

export interface ComposeRequest {
    // Already shrunk, if the zoom called for it. See reduce.ts.
    readonly image: SourceImage;
    // Device pixels per pixel of `image`. A power of two, and at least 1 for
    // anything the viewer asks for.
    readonly scale: number;
    // Device pixels per point. An integer in practice (1 or 2). Only the
    // checkerboard cares, since it's measured on the screen rather than in the
    // image.
    readonly dpr: number;
    // The output buffer and its size, in device pixels.
    readonly width: number;
    readonly height: number;
    readonly out: Uint8ClampedArray;
    // The image's top-left corner within the output.
    readonly originX: number;
    readonly originY: number;
    readonly background: Background;
}

function fillSolid(out: Uint8ClampedArray, start: number, end: number, color: Rgb): void {
    for (let i = start*4; i < end*4; i += 4) {
        out[i] = color.r;
        out[i + 1] = color.g;
        out[i + 2] = color.b;
        out[i + 3] = 255;
    }
}

export function compose(request: ComposeRequest): void {
    const { image, scale, dpr, width, height, out, originX, originY, background } = request;

    const solid = solidColor(background);
    const checkerSize = CHECKER_SIZE*dpr;

    // The columns that land on the image. Everything outside is the surround.
    const x0 = Math.max(0, originX);
    const x1 = Math.min(width, Math.ceil(originX + image.width*scale));
    const y0 = Math.max(0, originY);
    const y1 = Math.min(height, Math.ceil(originY + image.height*scale));

    // Which image column each output column shows.
    const columns = new Int32Array(Math.max(0, x1 - x0));
    for (let x = x0; x < x1; x++) {
        columns[x - x0] = Math.floor((x - originX)/scale);
    }

    // Consecutive output rows often show the same image row (when zoomed in) or
    // are entirely surround, so we compose one and copy it. At 16:1 that's most
    // of the work.
    let copyFrom = -1;
    let copySourceRow = 0;
    let copyCheckerRow = 0;

    for (let y = 0; y < height; y++) {
        const rowStart = y*width*4;
        const onImage = y >= y0 && y < y1;

        const sourceRow = onImage ? Math.floor((y - originY)/scale) : -1;
        const checkerRow = onImage && solid === undefined
            ? Math.floor((y - originY)/checkerSize) & 1
            : 0;

        if (copyFrom >= 0 && sourceRow === copySourceRow && checkerRow === copyCheckerRow) {
            out.copyWithin(rowStart, copyFrom, copyFrom + width*4);
            continue;
        }
        copyFrom = rowStart;
        copySourceRow = sourceRow;
        copyCheckerRow = checkerRow;

        if (!onImage) {
            fillSolid(out, y*width, (y + 1)*width, SURROUND);
            continue;
        }

        fillSolid(out, y*width, y*width + x0, SURROUND);
        fillSolid(out, y*width + x1, (y + 1)*width, SURROUND);

        const sourceRowStart = sourceRow*image.width;
        for (let x = x0; x < x1; x++) {
            const source = (sourceRowStart + columns[x - x0]!)*4;
            const alpha = image.data[source + 3]!;
            const destination = rowStart + x*4;

            if (alpha === 255) {
                out[destination] = image.data[source]!;
                out[destination + 1] = image.data[source + 1]!;
                out[destination + 2] = image.data[source + 2]!;
                out[destination + 3] = 255;
                continue;
            }

            let under = solid;
            if (under === undefined) {
                const checkerColumn = Math.floor((x - originX)/checkerSize) & 1;
                under = (checkerColumn ^ checkerRow) === 0 ? CHECKER_LIGHT : CHECKER_DARK;
            }

            const over = 255 - alpha;
            out[destination] = Math.round((image.data[source]!*alpha + under.r*over)/255);
            out[destination + 1] = Math.round((image.data[source + 1]!*alpha + under.g*over)/255);
            out[destination + 2] = Math.round((image.data[source + 2]!*alpha + under.b*over)/255);
            out[destination + 3] = 255;
        }
    }
}

// The image pixel under a point, given the point's position relative to the
// image's top-left corner. Picks the same pixel that compose() draws in that
// point's top-left device pixel, so the readout always matches the screen.
// Undefined when the point is off the image.
export function pixelAt(image: Size, zoom: number, pointX: number, pointY: number):
        { x: number; y: number } | undefined {

    const scale = zoomScale(zoom);
    const x = Math.floor(pointX/scale);
    const y = Math.floor(pointY/scale);

    if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        return undefined;
    }

    return { x, y };
}
