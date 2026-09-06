import { describe, expect, it } from "vitest";

import { CHECKER_DARK, CHECKER_LIGHT, SURROUND } from "../src/core/background.js";
import { compose, type ComposeRequest, pixelAt, type SourceImage }
    from "../src/core/compose.js";

// An image whose pixels encode their own coordinates, so it's easy to tell
// which one landed where.
function coordinateImage(width: number, height: number, alpha = 255): SourceImage {
    const data = new Uint8ClampedArray(width*height*4);
    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const i = (y*width + x)*4;
            data[i] = x;
            data[i + 1] = y;
            data[i + 2] = 0;
            data[i + 3] = alpha;
        }
    }
    return { width, height, data };
}

function run(options: Partial<ComposeRequest> & { image: SourceImage; width: number; height: number }) {
    const out = new Uint8ClampedArray(options.width*options.height*4);
    compose({
        zoom: 0,
        dpr: 1,
        originX: 0,
        originY: 0,
        background: "checkerboard",
        ...options,
        out,
    });

    return (x: number, y: number) => {
        const i = (y*options.width + x)*4;
        return [out[i]!, out[i + 1]!, out[i + 2]!, out[i + 3]!];
    };
}

const surround = [SURROUND.r, SURROUND.g, SURROUND.b, 255];

describe("compose", () => {
    it("copies an opaque image pixel for pixel at 1:1", () => {
        const at = run({ image: coordinateImage(4, 4), width: 4, height: 4 });
        expect(at(0, 0)).toEqual([0, 0, 0, 255]);
        expect(at(3, 2)).toEqual([3, 2, 0, 255]);
    });

    it("makes each pixel a block when zoomed in", () => {
        const at = run({ image: coordinateImage(2, 2), zoom: 2, width: 8, height: 8 });
        // Every device pixel in the top-left 4x4 block is image pixel (0,0).
        for (const [x, y] of [[0, 0], [3, 0], [0, 3], [3, 3]] as const) {
            expect(at(x, y)).toEqual([0, 0, 0, 255]);
        }
        expect(at(4, 0)).toEqual([1, 0, 0, 255]);
        expect(at(4, 4)).toEqual([1, 1, 0, 255]);
    });

    it("treats a retina display as another factor of two", () => {
        const at = run({ image: coordinateImage(2, 2), zoom: 0, dpr: 2, width: 4, height: 4 });
        expect(at(1, 1)).toEqual([0, 0, 0, 255]);
        expect(at(2, 2)).toEqual([1, 1, 0, 255]);
    });

    it("drops pixels when zoomed out, without averaging them", () => {
        const at = run({ image: coordinateImage(8, 8), zoom: -1, width: 4, height: 4 });
        expect(at(0, 0)).toEqual([0, 0, 0, 255]);
        expect(at(1, 0)).toEqual([2, 0, 0, 255]);
        expect(at(3, 3)).toEqual([6, 6, 0, 255]);
    });

    it("zooms out below one device pixel per image pixel", () => {
        // 1:4 on a retina display is one device pixel per two image pixels.
        const at = run({ image: coordinateImage(8, 8), zoom: -2, dpr: 2, width: 4, height: 4 });
        expect(at(0, 0)).toEqual([0, 0, 0, 255]);
        expect(at(1, 0)).toEqual([2, 0, 0, 255]);
        expect(at(3, 0)).toEqual([6, 0, 0, 255]);
    });

    it("fills the area outside the image with the surround", () => {
        const at = run({ image: coordinateImage(2, 2), width: 4, height: 4, originX: 1, originY: 1 });
        expect(at(0, 0)).toEqual(surround);
        expect(at(1, 1)).toEqual([0, 0, 0, 255]);
        expect(at(2, 2)).toEqual([1, 1, 0, 255]);
        expect(at(3, 3)).toEqual(surround);
    });

    it("handles a scrolled image, where the origin is negative", () => {
        const at = run({ image: coordinateImage(8, 8), width: 4, height: 4, originX: -4, originY: -2 });
        expect(at(0, 0)).toEqual([4, 2, 0, 255]);
        expect(at(3, 0)).toEqual([7, 2, 0, 255]);
    });

    it("draws the checkerboard 8 points on a side, starting light", () => {
        const image = coordinateImage(32, 32, 0);
        const at = run({ image, width: 32, height: 32 });

        const light = [CHECKER_LIGHT.r, CHECKER_LIGHT.g, CHECKER_LIGHT.b, 255];
        const dark = [CHECKER_DARK.r, CHECKER_DARK.g, CHECKER_DARK.b, 255];

        expect(at(0, 0)).toEqual(light);
        expect(at(7, 7)).toEqual(light);
        expect(at(8, 0)).toEqual(dark);
        expect(at(0, 8)).toEqual(dark);
        expect(at(8, 8)).toEqual(light);
    });

    it("scales the checkerboard with the display, not the zoom", () => {
        const image = coordinateImage(64, 64, 0);
        const at = run({ image, zoom: 2, dpr: 2, width: 64, height: 64 });

        const light = [CHECKER_LIGHT.r, CHECKER_LIGHT.g, CHECKER_LIGHT.b, 255];
        const dark = [CHECKER_DARK.r, CHECKER_DARK.g, CHECKER_DARK.b, 255];

        // 8 points is 16 device pixels, whatever the zoom.
        expect(at(15, 0)).toEqual(light);
        expect(at(16, 0)).toEqual(dark);
    });

    it("blends a translucent pixel over a solid background", () => {
        const image: SourceImage = {
            width: 1, height: 1,
            data: new Uint8ClampedArray([255, 255, 255, 128]),
        };

        expect(run({ image, width: 1, height: 1, background: "black" })(0, 0))
            .toEqual([128, 128, 128, 255]);
        expect(run({ image, width: 1, height: 1, background: "white" })(0, 0))
            .toEqual([255, 255, 255, 255]);
        expect(run({ image, width: 1, height: 1, background: "gray" })(0, 0))
            .toEqual([192, 192, 192, 255]);
    });

    it("leaves opaque pixels untouched by the background", () => {
        const image: SourceImage = {
            width: 1, height: 1,
            data: new Uint8ClampedArray([1, 2, 3, 255]),
        };
        expect(run({ image, width: 1, height: 1, background: "white" })(0, 0))
            .toEqual([1, 2, 3, 255]);
    });
});

describe("pixelAt", () => {
    const image = { width: 8, height: 8 };

    it("maps points to pixels at 1:1", () => {
        expect(pixelAt(image, 0, 3, 4)).toEqual({ x: 3, y: 4 });
    });

    it("picks the top-left pixel of a zoomed-in block", () => {
        expect(pixelAt(image, 2, 0, 0)).toEqual({ x: 0, y: 0 });
        expect(pixelAt(image, 2, 3, 3)).toEqual({ x: 0, y: 0 });
        expect(pixelAt(image, 2, 4, 4)).toEqual({ x: 1, y: 1 });
    });

    it("picks the top-left pixel of the group when zoomed out", () => {
        expect(pixelAt(image, -1, 1, 1)).toEqual({ x: 2, y: 2 });
    });

    it("is undefined off the image", () => {
        expect(pixelAt(image, 0, -1, 0)).toBeUndefined();
        expect(pixelAt(image, 0, 8, 0)).toBeUndefined();
        expect(pixelAt(image, 0, 0, 8)).toBeUndefined();
    });

    it("picks the pixel that compose draws in that point's first device pixel", () => {
        const source = coordinateImage(8, 8);
        for (const zoom of [-2, -1, 0, 1, 2]) {
            for (const dpr of [1, 2]) {
                const at = run({ image: source, zoom, dpr, width: 32, height: 32 });
                for (const point of [0, 1, 5]) {
                    const pixel = pixelAt(source, zoom, point, point);
                    if (pixel !== undefined) {
                        const device = Math.round(point*dpr);
                        expect([at(device, device)[0], at(device, device)[1]])
                            .toEqual([pixel.x, pixel.y]);
                    }
                }
            }
        }
    });
});
