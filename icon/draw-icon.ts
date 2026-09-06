// Draws the app icon procedurally, so that it's generated rather than checked
// in as a picture, using the same Canvas 2D that draws the images.
//
// Bundled as an IIFE and injected into a blank page by make-icon.ts, which is
// how it gets a canvas to draw on.

const WIDTH = 1024;
const HEIGHT = 1024;

// Geometry to match the macOS app icons: an 824x824 body in a 1024x1024 canvas,
// with corners rounded by about 23% of the width, and a small, faint shadow.
// The radius is the circular arc that best fits the shape macOS itself draws,
// whose corners are very slightly non-circular.
const MARGIN = 100;
const RADIUS = 193;
const SHADOW_SIZE = 14;
const SHADOW_OFFSET = 9;
// The shadow is a little wider than the body, not just nudged down.
const SHADOW_SPREAD = 5;
const SHADOW_COLOR = "rgb(0 0 0)";
const SHADOW_OPACITY = 0.19;

const BODY = WIDTH - MARGIN*2;

// The palette from lawrence-website's new.css, in its own order, which walks
// once around the hue wheel (99, 39, 26, 1, 293, 203) and so bands along the
// diagonals. Neighboring squares always differ by one step, so none ever match.
const COLORS: readonly string[] = [
    "#79B756", // green
    "#F2B749", // yellow
    "#E58337", // orange
    "#CE4946", // red
    "#85448F", // purple
    "#3F9BD5", // blue
];

// A grid of colored squares that runs to all four edges, so the icon fills its
// tile the way the system icons do. The gaps show the white body through, and
// the rounded corners cut the squares at the edge.
//
// One row per color, so the diagonals come out even and no color repeats within
// a row. Six also leaves the squares big enough to survive the 32-pixel icon.
const COUNT = COLORS.length;
// A fifth of a square, which keeps the white lines fine enough not to compete
// with the colors.
const GAP_RATIO = 0.2;
const SQUARE = BODY/(COUNT + (COUNT - 1)*GAP_RATIO);
const GAP = SQUARE*GAP_RATIO;

const BODY_COLOR = "#FFFFFF";

// Draw the icon at its full size. Smaller icons are scaled down from this
// master rather than drawn again at each size.
function drawMaster(ctx: CanvasRenderingContext2D): void {
    ctx.save();
    ctx.globalAlpha = SHADOW_OPACITY;
    ctx.drawImage(makeShadow(), 0, 0);
    ctx.restore();

    // Everything else is clipped to the rounded rect.
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(MARGIN, MARGIN, BODY, BODY, RADIUS);
    ctx.clip();

    ctx.fillStyle = BODY_COLOR;
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    for (let row = 0; row < COUNT; row++) {
        for (let column = 0; column < COUNT; column++) {
            ctx.fillStyle = COLORS[(row + column)%COLORS.length]!;
            ctx.fillRect(
                MARGIN + column*(SQUARE + GAP),
                MARGIN + row*(SQUARE + GAP),
                SQUARE, SQUARE);
        }
    }

    ctx.restore();
}

// The shadow: the same rounded rect, blurred and nudged downward. It's drawn on
// its own canvas because blurring a shape blurs its color along with its alpha,
// which leaves the color drifting by a few levels at the edges. Compositing a
// flat color through the blurred shape keeps it exactly constant.
function makeShadow(): HTMLCanvasElement {
    const canvas = makeCanvas(WIDTH, HEIGHT);
    const ctx = get2dContext(canvas);

    ctx.filter = `blur(${SHADOW_SIZE}px)`;
    ctx.fillStyle = SHADOW_COLOR;
    ctx.beginPath();
    ctx.roundRect(MARGIN - SHADOW_SPREAD, MARGIN + SHADOW_OFFSET - SHADOW_SPREAD,
        BODY + SHADOW_SPREAD*2, BODY + SHADOW_SPREAD*2,
        RADIUS + SHADOW_SPREAD);
    ctx.fill();
    ctx.filter = "none";

    ctx.globalCompositeOperation = "source-in";
    ctx.fillStyle = SHADOW_COLOR;
    ctx.fillRect(0, 0, WIDTH, HEIGHT);

    return canvas;
}

function get2dContext(canvas: HTMLCanvasElement): CanvasRenderingContext2D {
    const ctx = canvas.getContext("2d");
    if (ctx === null) {
        throw new Error("Can't get a 2D canvas context.");
    }

    return ctx;
}

function makeCanvas(width: number, height: number): HTMLCanvasElement {
    const canvas = document.createElement("canvas");

    canvas.width = width;
    canvas.height = height;

    return canvas;
}

// Shrink by halving repeatedly rather than in one step, which aliases badly at
// the small sizes: the grid turns into uneven stripes. Every size we need is a
// power of two, so the halves land exactly.
function shrinkTo(image: HTMLCanvasElement, size: number): HTMLCanvasElement {
    let current = image;

    while (current.width > size) {
        const width = Math.max(size, Math.floor(current.width/2));
        const smaller = makeCanvas(width, width);
        const ctx = get2dContext(smaller);

        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";
        ctx.drawImage(current, 0, 0, width, width);

        current = smaller;
    }

    return current;
}

// Return the icon at the given size as a PNG data URL.
function rViewIcon(size: number): string {
    const master = makeCanvas(WIDTH, HEIGHT);
    drawMaster(get2dContext(master));

    return shrinkTo(master, size).toDataURL("image/png");
}

// Injected into a blank page, so hand the function to whoever asks for it.
(globalThis as unknown as { rViewIcon: (size: number) => string }).rViewIcon = rViewIcon;
