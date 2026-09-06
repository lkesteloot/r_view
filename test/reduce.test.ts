import { describe, expect, it } from "vitest";

import { type SourceImage } from "../src/core/compose.js";
import { reduce, reductionFor } from "../src/core/reduce.js";

function image(width: number, height: number, pixels: number[][]): SourceImage {
    return { width, height, data: new Uint8ClampedArray(pixels.flat()) };
}

function pixel(source: SourceImage, x: number, y: number): number[] {
    const i = (y*source.width + x)*4;
    return [...source.data.slice(i, i + 4)];
}

describe("reductionFor", () => {
    it("is 1 whenever every image pixel gets a device pixel of its own", () => {
        expect(reductionFor(0, 1)).toBe(1);
        expect(reductionFor(2, 1)).toBe(1);
        expect(reductionFor(4, 2)).toBe(1);
        // 1:2 on a retina display shows the image at the display's resolution.
        expect(reductionFor(-1, 2)).toBe(1);
    });

    it("counts how many image pixels share a device pixel", () => {
        expect(reductionFor(-1, 1)).toBe(2);
        expect(reductionFor(-4, 1)).toBe(16);
        expect(reductionFor(-2, 2)).toBe(2);
        expect(reductionFor(-4, 2)).toBe(8);
    });
});

describe("reduce", () => {
    it("returns the image untouched when there's nothing to average", () => {
        const source = image(1, 1, [[1, 2, 3, 255]]);
        expect(reduce(source, 1)).toBe(source);
    });

    it("averages a block down to one pixel", () => {
        const source = image(2, 2, [
            [0, 0, 0, 255], [100, 100, 100, 255],
            [200, 200, 200, 255], [255, 255, 255, 255],
        ]);
        // (0 + 100 + 200 + 255)/4 = 138.75, rounded.
        expect(pixel(reduce(source, 2), 0, 0)).toEqual([139, 139, 139, 255]);
    });

    it("keeps blocks separate", () => {
        const source = image(4, 2, [
            [10, 10, 10, 255], [20, 20, 20, 255], [200, 200, 200, 255], [200, 200, 200, 255],
            [30, 30, 30, 255], [40, 40, 40, 255], [200, 200, 200, 255], [200, 200, 200, 255],
        ]);
        const reduced = reduce(source, 2);
        expect([reduced.width, reduced.height]).toEqual([2, 1]);
        expect(pixel(reduced, 0, 0)).toEqual([25, 25, 25, 255]);
        expect(pixel(reduced, 1, 0)).toEqual([200, 200, 200, 255]);
    });

    it("averages a partial block at the edge over just the pixels there", () => {
        // 3 wide reduced by 2: the second block holds a single pixel.
        const source = image(3, 1, [
            [0, 0, 0, 255], [100, 100, 100, 255], [60, 60, 60, 255],
        ]);
        const reduced = reduce(source, 2);
        expect([reduced.width, reduced.height]).toEqual([2, 1]);
        expect(pixel(reduced, 0, 0)).toEqual([50, 50, 50, 255]);
        expect(pixel(reduced, 1, 0)).toEqual([60, 60, 60, 255]);
    });

    it("averages alpha over the whole block", () => {
        const source = image(2, 1, [[0, 0, 0, 255], [0, 0, 0, 0]]);
        expect(pixel(reduce(source, 2), 0, 0)[3]).toBe(128);
    });

    it("doesn't let a transparent pixel's color bleed into its neighbors", () => {
        // A red pixel next to a fully transparent green one. The green is
        // invisible, so the result must stay red.
        const source = image(2, 1, [[255, 0, 0, 255], [0, 255, 0, 0]]);
        const reduced = reduce(source, 2);
        expect(pixel(reduced, 0, 0).slice(0, 3)).toEqual([255, 0, 0]);
        expect(pixel(reduced, 0, 0)[3]).toBe(128);
    });

    it("weights color by alpha", () => {
        // Full-strength black and half-strength white: the white counts half.
        const source = image(2, 1, [[0, 0, 0, 255], [255, 255, 255, 128]]);
        // (0*255 + 255*128)/(255 + 128) = 85.2
        expect(pixel(reduce(source, 2), 0, 0).slice(0, 3)).toEqual([85, 85, 85]);
    });

    it("leaves a wholly transparent block transparent", () => {
        const source = image(2, 1, [[10, 20, 30, 0], [40, 50, 60, 0]]);
        expect(pixel(reduce(source, 2), 0, 0)).toEqual([0, 0, 0, 0]);
    });

    it("reduces by more than two at a time", () => {
        const data: number[][] = [];
        for (let i = 0; i < 16; i++) {
            data.push([i*16, 0, 0, 255]);
        }
        const reduced = reduce(image(4, 4, data), 4);
        expect([reduced.width, reduced.height]).toEqual([1, 1]);
        // The mean of 0, 16, ... 240.
        expect(pixel(reduced, 0, 0)[0]).toBe(120);
    });

    it("sizes the result the way the layout expects", () => {
        expect(reduce(image(5, 5, Array(25).fill([0, 0, 0, 255])), 2).width).toBe(3);
        expect(reduce(image(5, 5, Array(25).fill([0, 0, 0, 255])), 4).width).toBe(2);
    });
});
