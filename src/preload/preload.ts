// The only bridge between the main process and the renderer. The renderer has
// no Node access: all it can do is receive an image and how to display it, and
// report back the image's size and the color the user sampled.

import { contextBridge, ipcRenderer } from "electron";

import { type Background } from "../core/background.js";

export interface ImageMessage {
    // What to show in the title bar: a basename, or "Clipboard".
    readonly name: string;
    readonly bytes: Uint8Array;
    readonly mimeType: string | undefined;
}

// How to display the image. The main process owns this, because it also needs
// it to size the window and check the right menu items.
export interface ViewMessage {
    readonly zoom: number;
    readonly background: Background;
}

export interface RViewApi {
    onImage(callback: (message: ImageMessage) => void): void;
    onView(callback: (message: ViewMessage) => void): void;
    // The image decoded; the main process can now pick a zoom and size the window.
    loaded(size: { width: number; height: number }): void;
    failed(message: string): void;
    // The color under the mouse, for Copy Color. Undefined before the first sample.
    sampled(hex: string | undefined): void;
}

const api: RViewApi = {
    onImage(callback) {
        ipcRenderer.on("image", (_event, message) => callback(message));
    },
    onView(callback) {
        ipcRenderer.on("view", (_event, message) => callback(message));
    },
    loaded(size) {
        ipcRenderer.send("loaded", size);
    },
    failed(message) {
        ipcRenderer.send("failed", message);
    },
    sampled(hex) {
        ipcRenderer.send("sampled", hex);
    },
};

contextBridge.exposeInMainWorld("rview", api);
