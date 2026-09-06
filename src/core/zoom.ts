// Zoom levels. A zoom is an integer exponent: the image is scaled by 2^zoom,
// so 0 is 1:1, -1 is 1:2 (half size), and 1 is 2:1 (double size). Keeping the
// exponent rather than the ratio means every scale factor is a power of two,
// which is what lets the compositor sample pixels exactly (see compose.ts).

export const MIN_ZOOM = -4; // 1:16
export const MAX_ZOOM = 4; // 16:1

export interface Size {
    readonly width: number;
    readonly height: number;
}

export function clampZoom(zoom: number): number {
    return Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, zoom));
}

// Points per image pixel. 0.25 at 1:4, 4 at 4:1.
export function zoomScale(zoom: number): number {
    return 2**zoom;
}

// "1:2" or "2:1", or undefined at 1:1, where we leave it out of the title.
export function zoomLabel(zoom: number): string | undefined {
    if (zoom === 0) {
        return undefined;
    }
    return zoom > 0 ? `${2**zoom}:1` : `1:${2**-zoom}`;
}

// The size of the image on screen, in points. Rounded up, since a 5-pixel-wide
// image at 1:2 still needs 3 points to show pixels 0, 2 and 4.
export function zoomedSize(image: Size, zoom: number): Size {
    const scale = zoomScale(zoom);
    return {
        width: Math.ceil(image.width*scale),
        height: Math.ceil(image.height*scale),
    };
}

// The largest zoom, up to maxZoom, at which the whole image fits in the
// available space. The default ceiling of 1:1 is what opening a file wants: a
// small image should open at actual size, not blown up to fill the screen.
// View > Zoom to Fit passes MAX_ZOOM, since asking to fit means both ways.
export function fitZoom(image: Size, available: Size, maxZoom = 0): number {
    let zoom = clampZoom(maxZoom);

    while (zoom > MIN_ZOOM) {
        const size = zoomedSize(image, zoom);
        if (size.width <= available.width && size.height <= available.height) {
            break;
        }
        zoom -= 1;
    }

    return zoom;
}
