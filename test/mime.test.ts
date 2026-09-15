import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

import { IMAGE_EXTENSIONS, mimeTypeFor, mimeTypeFromName, sniffMimeType }
    from "../src/core/mime.js";

function bytes(...values: (number | string)[]): Uint8Array {
    const out: number[] = [];
    for (const value of values) {
        if (typeof value === "number") {
            out.push(value);
        } else {
            out.push(...[...value].map((c) => c.charCodeAt(0)));
        }
    }
    return new Uint8Array(out);
}

describe("sniffMimeType", () => {
    it("recognizes the formats we can decode", () => {
        expect(sniffMimeType(bytes(0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A))).toBe("image/png");
        expect(sniffMimeType(bytes(0xFF, 0xD8, 0xFF, 0xE0))).toBe("image/jpeg");
        expect(sniffMimeType(bytes("GIF89a"))).toBe("image/gif");
        expect(sniffMimeType(bytes("RIFF", 0, 0, 0, 0, "WEBP"))).toBe("image/webp");
        expect(sniffMimeType(bytes("BM", 0, 0))).toBe("image/bmp");
        expect(sniffMimeType(bytes(0, 0, 1, 0))).toBe("image/x-icon");
        expect(sniffMimeType(bytes(0, 0, 0, 0x20, "ftypavif"))).toBe("image/avif");
    });

    it("doesn't guess at something it hasn't seen", () => {
        expect(sniffMimeType(bytes("hello"))).toBeUndefined();
        expect(sniffMimeType(bytes())).toBeUndefined();
        // Truncated signature.
        expect(sniffMimeType(bytes(0x89, "PN"))).toBeUndefined();
        // An ISO container that isn't AVIF.
        expect(sniffMimeType(bytes(0, 0, 0, 0x20, "ftypheic"))).toBeUndefined();
    });
});

describe("mimeTypeFromName", () => {
    it("maps extensions, ignoring case", () => {
        expect(mimeTypeFromName("foo.PNG")).toBe("image/png");
        expect(mimeTypeFromName("a.b.jpeg")).toBe("image/jpeg");
    });

    it("is undefined for names it doesn't know", () => {
        expect(mimeTypeFromName("foo.txt")).toBeUndefined();
        expect(mimeTypeFromName("noextension")).toBeUndefined();
    });
});

describe("mimeTypeFor", () => {
    it("believes the bytes over the name", () => {
        expect(mimeTypeFor("lying.jpg", bytes(0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A)))
            .toBe("image/png");
    });

    it("falls back to the name when the bytes say nothing", () => {
        expect(mimeTypeFor("foo.png", bytes("junk"))).toBe("image/png");
    });
});

// Finder offers r_view in Open With only for the types its Info.plist declares,
// and those are UTIs rather than extensions. These are what macOS itself maps
// each extension to (UTType(filenameExtension:)).
const UTI_FOR_EXTENSION = new Map<string, string>([
    ["png", "public.png"],
    ["jpg", "public.jpeg"],
    ["jpeg", "public.jpeg"],
    ["jpe", "public.jpeg"],
    ["gif", "com.compuserve.gif"],
    ["webp", "org.webmproject.webp"],
    ["avif", "public.avif"],
    ["bmp", "com.microsoft.bmp"],
    ["ico", "com.microsoft.ico"],
]);

describe("the document types declared to Finder", () => {
    const packageJson = JSON.parse(
        readFileSync(new URL("../package.json", import.meta.url), "utf8"));
    const declared: string[] = packageJson.build.mac.extendInfo.CFBundleDocumentTypes
        .flatMap((type: { LSItemContentTypes: string[] }) => type.LSItemContentTypes);

    it("know the UTI of every format we can open", () => {
        for (const extension of IMAGE_EXTENSIONS) {
            expect(UTI_FOR_EXTENSION.get(extension), extension).toBeDefined();
        }
    });

    it("match the formats we can open, no more and no fewer", () => {
        const wanted = new Set(IMAGE_EXTENSIONS.map((extension) => UTI_FOR_EXTENSION.get(extension)));
        expect(new Set(declared)).toEqual(wanted);
    });
});
