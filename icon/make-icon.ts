// Generates icon/r_view.icns from draw-icon.ts. Run with "make icon".
//
// This runs under Electron because that's where we have a canvas. It draws into
// a blank page and writes out the sizes that "iconutil" wants, plus one plain
// PNG for the README.

import { app, BrowserWindow } from "electron";
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const ICON_DIR = resolve(__dirname);
const ICONSET_DIR = resolve(ICON_DIR, "r_view.iconset");
const ICNS = resolve(ICON_DIR, "r_view.icns");
const README_PNG = resolve(ICON_DIR, "r_view.png");
const README_SIZE = 256;

// The sizes in a macOS iconset, as [size in points, scale].
const SIZES: readonly [number, number][] = [
    [16, 1], [16, 2],
    [32, 1], [32, 2],
    [128, 1], [128, 2],
    [256, 1], [256, 2],
    [512, 1], [512, 2],
];

function iconsetName(size: number, scale: number): string {
    return `icon_${size}x${size}${scale === 1 ? "" : `@${scale}x`}.png`;
}

app.whenReady().then(async () => {
    const window = new BrowserWindow({ show: false, width: 100, height: 100 });
    await window.loadURL("about:blank");

    // Inject the drawing code, which defines rViewIcon().
    await window.webContents.executeJavaScript(
        readFileSync(resolve(ICON_DIR, "draw-icon.js"), "utf8"));

    const render = async (pixels: number): Promise<Buffer> => {
        const dataUrl: string = await window.webContents.executeJavaScript(
            `rViewIcon(${pixels})`);
        return Buffer.from(dataUrl.split(",")[1]!, "base64");
    };

    rmSync(ICONSET_DIR, { recursive: true, force: true });
    mkdirSync(ICONSET_DIR, { recursive: true });

    for (const [size, scale] of SIZES) {
        const pixels = size*scale;
        writeFileSync(resolve(ICONSET_DIR, iconsetName(size, scale)), await render(pixels));
        console.log(`${iconsetName(size, scale)} (${pixels}x${pixels})`);
    }

    execFileSync("iconutil", ["-c", "icns", ICONSET_DIR, "-o", ICNS]);
    console.log(`Wrote ${ICNS}`);

    writeFileSync(README_PNG, await render(README_SIZE));
    console.log(`Wrote ${README_PNG}`);

    app.exit(0);
});
