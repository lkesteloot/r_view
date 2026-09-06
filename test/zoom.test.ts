import { describe, expect, it } from "vitest";

import { clampZoom, fitZoom, MAX_ZOOM, MIN_ZOOM, zoomedSize, zoomLabel, zoomScale }
    from "../src/core/zoom.js";

describe("zoomScale", () => {
    it("is a power of two", () => {
        expect(zoomScale(0)).toBe(1);
        expect(zoomScale(1)).toBe(2);
        expect(zoomScale(4)).toBe(16);
        expect(zoomScale(-1)).toBe(0.5);
        expect(zoomScale(-4)).toBe(1/16);
    });
});

describe("zoomLabel", () => {
    it("is left out at 1:1", () => {
        expect(zoomLabel(0)).toBeUndefined();
    });

    it("reads as a ratio", () => {
        expect(zoomLabel(-1)).toBe("1:2");
        expect(zoomLabel(-4)).toBe("1:16");
        expect(zoomLabel(1)).toBe("2:1");
        expect(zoomLabel(4)).toBe("16:1");
    });
});

describe("clampZoom", () => {
    it("stops at the ends of the range", () => {
        expect(clampZoom(MIN_ZOOM - 1)).toBe(MIN_ZOOM);
        expect(clampZoom(MAX_ZOOM + 1)).toBe(MAX_ZOOM);
        expect(clampZoom(0)).toBe(0);
    });
});

describe("zoomedSize", () => {
    it("scales up exactly", () => {
        expect(zoomedSize({ width: 100, height: 50 }, 2)).toEqual({ width: 400, height: 200 });
    });

    it("rounds up when zoomed out, since a partial pixel still needs a point", () => {
        expect(zoomedSize({ width: 5, height: 5 }, -1)).toEqual({ width: 3, height: 3 });
        expect(zoomedSize({ width: 4, height: 4 }, -1)).toEqual({ width: 2, height: 2 });
    });
});

describe("fitZoom", () => {
    const screen = { width: 1000, height: 800 };

    it("leaves an image that fits at 1:1", () => {
        expect(fitZoom({ width: 1000, height: 800 }, screen)).toBe(0);
    });

    it("never zooms in, however small the image", () => {
        expect(fitZoom({ width: 10, height: 10 }, screen)).toBe(0);
    });

    it("zooms out by powers of two until it fits", () => {
        expect(fitZoom({ width: 1001, height: 800 }, screen)).toBe(-1);
        expect(fitZoom({ width: 4000, height: 800 }, screen)).toBe(-2);
        expect(fitZoom({ width: 8000, height: 800 }, screen)).toBe(-3);
    });

    it("considers both dimensions", () => {
        expect(fitZoom({ width: 10, height: 3200 }, screen)).toBe(-2);
    });

    it("gives up at the smallest zoom", () => {
        expect(fitZoom({ width: 1000000, height: 1000000 }, screen)).toBe(MIN_ZOOM);
    });

    // View > Zoom to Fit raises the ceiling, since asking to fit means both ways.
    describe("with a higher ceiling", () => {
        it("zooms in until the image fills the window", () => {
            expect(fitZoom({ width: 100, height: 100 }, screen, MAX_ZOOM)).toBe(3);
            expect(fitZoom({ width: 500, height: 400 }, screen, MAX_ZOOM)).toBe(1);
        });

        it("stops at the largest zoom, however small the image", () => {
            expect(fitZoom({ width: 1, height: 1 }, screen, MAX_ZOOM)).toBe(MAX_ZOOM);
        });

        it("still zooms out when the image is too big", () => {
            expect(fitZoom({ width: 4000, height: 800 }, screen, MAX_ZOOM)).toBe(-2);
        });

        it("leaves an image that already fills the window alone", () => {
            expect(fitZoom({ width: 1000, height: 800 }, screen, MAX_ZOOM)).toBe(0);
        });

        it("never exceeds the range, whatever ceiling it's given", () => {
            expect(fitZoom({ width: 1, height: 1 }, screen, 99)).toBe(MAX_ZOOM);
        });
    });
});
