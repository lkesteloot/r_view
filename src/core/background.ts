// What semi-transparent images are drawn over, and what fills the window
// around the image.

export const BACKGROUNDS = ["checkerboard", "black", "gray", "white"] as const;
export type Background = (typeof BACKGROUNDS)[number];

export const DEFAULT_BACKGROUND: Background = "checkerboard";

export function isBackground(value: unknown): value is Background {
    return BACKGROUNDS.includes(value as Background);
}

// An opaque color, one byte per channel.
export interface Rgb {
    readonly r: number;
    readonly g: number;
    readonly b: number;
}

// The window outside the image. Not configurable: it's not part of the picture,
// and a mid-gray keeps it from being mistaken for one.
export const SURROUND: Rgb = { r: 0x92, g: 0x92, b: 0x92 };

export const CHECKER_LIGHT: Rgb = { r: 0xFF, g: 0xFF, b: 0xFF };
export const CHECKER_DARK: Rgb = { r: 0xCC, g: 0xCC, b: 0xCC };

// The side of a checkerboard square, in points. Screen space, so the squares
// stay the same size on screen no matter the zoom.
export const CHECKER_SIZE = 8;

const BLACK: Rgb = { r: 0, g: 0, b: 0 };
const GRAY: Rgb = { r: 0x80, g: 0x80, b: 0x80 };
const WHITE: Rgb = { r: 0xFF, g: 0xFF, b: 0xFF };

// The solid color of a background, or undefined for the checkerboard, which
// depends on the position of the pixel.
export function solidColor(background: Background): Rgb | undefined {
    switch (background) {
        case "checkerboard": return undefined;
        case "black": return BLACK;
        case "gray": return GRAY;
        case "white": return WHITE;
    }
}

export function backgroundLabel(background: Background): string {
    switch (background) {
        case "checkerboard": return "Checkerboard";
        case "black": return "Black";
        case "gray": return "Gray";
        case "white": return "White";
    }
}
