// Shows the image in the window: lays out the scrolling area, composes the
// visible pixels, and samples the color under the mouse.

import { type Background, DEFAULT_BACKGROUND } from "../core/background.js";
import { compose, pixelAt, type SourceImage } from "../core/compose.js";
import { reduce, reductionFor } from "../core/reduce.js";
import { colorHex, formatTitle, type Sample } from "../core/title.js";
import { zoomedSize, zoomScale } from "../core/zoom.js";

export class Viewer {
    private image: SourceImage | undefined = undefined;
    // The image shrunk for the current zoom, and by how much. Kept between
    // frames: panning redraws constantly, and averaging the image down again
    // every frame would be wasted work. Only a zoom -- or moving the window to
    // a display with a different pixel ratio -- invalidates it.
    private reduced: SourceImage | undefined = undefined;
    private reduction = 0;
    private name = "";
    private zoom = 0;
    private background: Background = DEFAULT_BACKGROUND;
    // The pixel the user last sampled. Kept when the mouse leaves the image or
    // the button comes up, so the reading stays on screen to be read.
    private sample: Sample | undefined = undefined;
    private sampling = false;

    // Where the image's top-left corner sits in the scrolling area, in points.
    // Non-zero when the image is smaller than the window and gets centered.
    private offsetX = 0;
    private offsetY = 0;

    private buffer: ImageData | undefined = undefined;
    private readonly ctx: CanvasRenderingContext2D;
    private drawPending = false;

    constructor(
        private readonly scroller: HTMLElement,
        private readonly spacer: HTMLElement,
        private readonly canvas: HTMLCanvasElement,
        private readonly onSampled: (hex: string | undefined) => void) {

        const ctx = canvas.getContext("2d", { colorSpace: "srgb", alpha: false });
        if (ctx === null) {
            throw new Error("Can't get a 2D canvas context.");
        }
        this.ctx = ctx;

        this.scroller.addEventListener("scroll", () => this.requestDraw());
        this.scroller.addEventListener("mousedown", (event) => {
            this.sampling = true;
            this.sampleAt(event);
        });
        window.addEventListener("mousemove", (event) => {
            if (this.sampling) {
                this.sampleAt(event);
            }
        });
        window.addEventListener("mouseup", () => {
            this.sampling = false;
        });
        window.addEventListener("resize", () => this.relayout());
    }

    setImage(name: string, image: SourceImage): void {
        this.name = name;
        this.image = image;
        this.reduced = undefined;
        this.reduction = 0;
        this.sample = undefined;
        this.onSampled(undefined);
        this.relayout();
    }

    setView(zoom: number, background: Background): void {
        const oldZoom = this.zoom;
        this.zoom = zoom;
        this.background = background;

        if (zoom !== oldZoom) {
            this.relayout(oldZoom);
        } else {
            this.updateTitle();
            this.requestDraw();
        }
    }

    // Size the scrolling area to the zoomed image and the canvas to the window.
    // When the zoom changed, keep whatever was in the middle of the window in
    // the middle of the window.
    private relayout(oldZoom?: number): void {
        const image = this.image;
        if (image === undefined) {
            return;
        }

        const centered = oldZoom === undefined ? undefined : this.centerImagePoint(oldZoom);

        const zoomed = zoomedSize(image, this.zoom);
        this.spacer.style.width = `${zoomed.width}px`;
        this.spacer.style.height = `${zoomed.height}px`;

        // Read the viewport only after the scrolling area is its new size, so
        // that scrollbars that take up room are accounted for.
        const viewportWidth = this.scroller.clientWidth;
        const viewportHeight = this.scroller.clientHeight;

        this.spacer.style.width = `${Math.max(zoomed.width, viewportWidth)}px`;
        this.spacer.style.height = `${Math.max(zoomed.height, viewportHeight)}px`;

        this.offsetX = Math.floor(Math.max(0, viewportWidth - zoomed.width)/2);
        this.offsetY = Math.floor(Math.max(0, viewportHeight - zoomed.height)/2);

        this.canvas.style.width = `${viewportWidth}px`;
        this.canvas.style.height = `${viewportHeight}px`;

        const ratio = window.devicePixelRatio;
        this.canvas.width = Math.round(viewportWidth*ratio);
        this.canvas.height = Math.round(viewportHeight*ratio);

        if (centered !== undefined) {
            const scale = zoomScale(this.zoom);
            this.scroller.scrollLeft = centered.x*scale + this.offsetX - viewportWidth/2;
            this.scroller.scrollTop = centered.y*scale + this.offsetY - viewportHeight/2;
        }

        this.updateTitle();
        this.draw();
    }

    // The image coordinate at the middle of the window, used as the anchor when
    // zooming.
    private centerImagePoint(zoom: number): { x: number; y: number } {
        const scale = zoomScale(zoom);
        return {
            x: (this.scroller.scrollLeft + this.scroller.clientWidth/2 - this.offsetX)/scale,
            y: (this.scroller.scrollTop + this.scroller.clientHeight/2 - this.offsetY)/scale,
        };
    }

    // The image shrunk to suit the zoom, averaging away the pixels that don't
    // fit on the screen. Returns the image itself when nothing has to go.
    private imageForDisplay(ratio: number): SourceImage | undefined {
        const image = this.image;
        if (image === undefined) {
            return undefined;
        }

        const reduction = reductionFor(this.zoom, ratio);
        if (this.reduced === undefined || this.reduction !== reduction) {
            this.reduction = reduction;
            this.reduced = reduce(image, reduction);
        }

        return this.reduced;
    }

    private requestDraw(): void {
        if (this.drawPending) {
            return;
        }
        this.drawPending = true;
        requestAnimationFrame(() => {
            this.drawPending = false;
            this.draw();
        });
    }

    private draw(): void {
        const ratio = window.devicePixelRatio;
        const image = this.imageForDisplay(ratio);
        if (image === undefined) {
            return;
        }

        const width = this.canvas.width;
        const height = this.canvas.height;
        if (width === 0 || height === 0) {
            return;
        }

        if (this.buffer === undefined
                || this.buffer.width !== width || this.buffer.height !== height) {
            this.buffer = new ImageData(width, height, { colorSpace: "srgb" });
        }

        // Move the canvas and fill it in the same frame, so its contents can't
        // slide against its position while the window is scrolling. Both are
        // snapped to whole device pixels: a canvas at a fractional position
        // would be resampled by the compositor, which is exactly the kind of
        // blurring this program exists to avoid.
        const scrollX = Math.round(this.scroller.scrollLeft*ratio);
        const scrollY = Math.round(this.scroller.scrollTop*ratio);
        this.canvas.style.transform = `translate(${scrollX/ratio}px, ${scrollY/ratio}px)`;

        compose({
            image,
            // The image has already been shrunk by this.reduction, so what's
            // left is always a whole number of device pixels per pixel.
            scale: zoomScale(this.zoom)*ratio*this.reduction,
            dpr: ratio,
            width,
            height,
            out: this.buffer.data,
            originX: Math.round(this.offsetX*ratio) - scrollX,
            originY: Math.round(this.offsetY*ratio) - scrollY,
            background: this.background,
        });

        this.ctx.putImageData(this.buffer, 0, 0);
    }

    private sampleAt(event: MouseEvent): void {
        const image = this.image;
        if (image === undefined) {
            return;
        }

        const bounds = this.scroller.getBoundingClientRect();
        const pointX = event.clientX - bounds.left + this.scroller.scrollLeft - this.offsetX;
        const pointY = event.clientY - bounds.top + this.scroller.scrollTop - this.offsetY;

        const pixel = pixelAt(image, this.zoom, pointX, pointY);
        if (pixel === undefined) {
            // Off the image. Leave the last reading up rather than blanking it.
            return;
        }

        const index = (pixel.y*image.width + pixel.x)*4;
        this.sample = {
            x: pixel.x,
            y: pixel.y,
            color: {
                r: image.data[index]!,
                g: image.data[index + 1]!,
                b: image.data[index + 2]!,
                a: image.data[index + 3]!,
            },
        };

        this.updateTitle();
        this.onSampled(colorHex(this.sample.color));
    }

    private updateTitle(): void {
        document.title = formatTitle(this.name, this.zoom, this.sample);
    }
}
