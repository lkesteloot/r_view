import { describe, expect, it } from "vitest";

import { colorHex, formatTitle } from "../src/core/title.js";

const OPAQUE = { r: 10, g: 20, b: 30, a: 255 };
const TRANSLUCENT = { r: 10, g: 20, b: 30, a: 40 };

describe("colorHex", () => {
    it("leaves out alpha when the pixel is opaque", () => {
        expect(colorHex(OPAQUE)).toBe("0A141E");
    });

    it("includes alpha otherwise", () => {
        expect(colorHex(TRANSLUCENT)).toBe("0A141E28");
        expect(colorHex({ r: 0, g: 0, b: 0, a: 0 })).toBe("00000000");
    });

    it("is uppercase and zero padded", () => {
        expect(colorHex({ r: 255, g: 1, b: 171, a: 255 })).toBe("FF01AB");
    });
});

describe("formatTitle", () => {
    it("is just the name at 1:1 with nothing sampled", () => {
        expect(formatTitle("foo.png", 0, undefined)).toBe("foo.png");
    });

    it("adds the zoom when it isn't 1:1", () => {
        expect(formatTitle("foo.png", -1, undefined)).toBe("foo.png - zoom 1:2");
        expect(formatTitle("foo.png", 2, undefined)).toBe("foo.png - zoom 4:1");
    });

    it("adds the sampled pixel", () => {
        expect(formatTitle("foo.png", -1, { x: 10, y: 20, color: TRANSLUCENT }))
            .toBe("foo.png - zoom 1:2 - (10,20) -> (10,20,30,40) #0A141E28");
    });

    it("leaves alpha out of an opaque sample", () => {
        expect(formatTitle("foo.png", 0, { x: 1, y: 2, color: OPAQUE }))
            .toBe("foo.png - (1,2) -> (10,20,30) #0A141E");
    });
});
