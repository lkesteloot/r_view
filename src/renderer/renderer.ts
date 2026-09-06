// Wires the window up to the viewer.

import { decodeImage } from "./decode.js";
import { type RViewApi } from "../preload/preload.js";
import { Viewer } from "./viewer.js";

declare global {
    interface Window {
        rview: RViewApi;
    }
}

function element<T extends HTMLElement>(id: string): T {
    const found = document.querySelector<T>(`#${id}`);
    if (found === null) {
        throw new Error(`Can't find #${id}.`);
    }
    return found;
}

const viewer = new Viewer(
    element("scroller"),
    element("spacer"),
    element<HTMLCanvasElement>("view"),
    (hex) => window.rview.sampled(hex));

window.rview.onView(({ zoom, background }) => viewer.setView(zoom, background));

window.rview.onImage(({ name, bytes, mimeType }) => {
    void (async () => {
        try {
            const image = await decodeImage(bytes, mimeType);
            viewer.setImage(name, image);
            window.rview.loaded({ width: image.width, height: image.height });
        } catch (error) {
            console.error(error);
            window.rview.failed(error instanceof Error ? error.message : String(error));
        }
    })();
});
