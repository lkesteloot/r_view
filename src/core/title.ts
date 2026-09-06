// The window title, which is also the readout: the filename, the zoom when it
// isn't 1:1, and the pixel the user last sampled.
//
//     foo.png - zoom 1:2 - (10,20) -> (10,20,30,40) #0A141E28
//
// Alpha is left out of both the decimal and the hex when it's 255, so opaque
// images read as plain RGB.

import { zoomLabel } from "./zoom.js";

export interface Rgba {
    readonly r: number;
    readonly g: number;
    readonly b: number;
    readonly a: number;
}

// A pixel the user sampled, in image coordinates.
export interface Sample {
    readonly x: number;
    readonly y: number;
    readonly color: Rgba;
}

function hex2(value: number): string {
    return value.toString(16).toUpperCase().padStart(2, "0");
}

// "0A141E28", or "0A141E" if opaque. No leading "#", since this is also what
// Copy Color puts on the clipboard.
export function colorHex(color: Rgba): string {
    const rgb = hex2(color.r) + hex2(color.g) + hex2(color.b);
    return color.a === 255 ? rgb : rgb + hex2(color.a);
}

function colorDecimal(color: Rgba): string {
    const rgb = `${color.r},${color.g},${color.b}`;
    return color.a === 255 ? rgb : `${rgb},${color.a}`;
}

export function formatTitle(name: string, zoom: number, sample: Sample | undefined): string {
    let title = name;

    const label = zoomLabel(zoom);
    if (label !== undefined) {
        title += ` - zoom ${label}`;
    }

    if (sample !== undefined) {
        title += ` - (${sample.x},${sample.y})`;
        title += ` -> (${colorDecimal(sample.color)}) #${colorHex(sample.color)}`;
    }

    return title;
}
