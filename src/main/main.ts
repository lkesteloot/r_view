// The main process: owns the command line, the windows, and the menu. It also
// owns the zoom and the background, because it needs both to size the window
// and to check the right menu items; the renderer just draws what it's told.

import { app, BrowserWindow, clipboard, dialog, ipcMain, Menu, screen, shell } from "electron";
import { readFile } from "node:fs/promises";
import { basename, resolve } from "node:path";

import {
    type Background, BACKGROUNDS, backgroundLabel, DEFAULT_BACKGROUND, SURROUND,
} from "../core/background.js";
import { IMAGE_EXTENSIONS, mimeTypeFor } from "../core/mime.js";
import { clampZoom, fitZoom, MAX_ZOOM, MIN_ZOOM, type Size, zoomedSize } from "../core/zoom.js";
import { type ImageMessage } from "../preload/preload.js";
import { filenamesFromArgv } from "./commandline.js";

// Matches the area around the image, so there's no white flash on open.
const BACKGROUND_COLOR = "#" + [SURROUND.r, SURROUND.g, SURROUND.b]
    .map((channel) => channel.toString(16).padStart(2, "0"))
    .join("");

// The smallest window we'll open, in points. A window really does match the
// size of its image, but a 16x16 icon would otherwise get a window too narrow
// to show the title bar, and the title bar is where this program says
// everything it has to say. The image is centered on the surround, the same as
// any other window bigger than its image. Only the initial size is affected:
// the user can still resize a window as small as they like.
const MIN_CONTENT = { width: 400, height: 120 };

// How far each new window is offset from the last, so they don't stack exactly.
const CASCADE = 24;
const CASCADE_COUNT = 8;

interface View {
    readonly name: string;
    // Undefined for images pasted from the clipboard.
    readonly filePath: string | undefined;
    // Undefined until the renderer has decoded the image.
    imageSize: Size | undefined;
    zoom: number;
    background: Background;
    // The last color the user sampled, for Copy Color.
    hex: string | undefined;
}

const views = new Map<number, View>();
let cascade = 0;

// The window the menu applies to. Usually the focused one, but the app can be
// in the background — or a window can be mid-open — while the menu is being
// built, and a menu that goes dead whenever the app isn't frontmost would greet
// the user with everything grayed out.
let lastFocused: BrowserWindow | undefined = undefined;

function currentWindow(): BrowserWindow | undefined {
    const focused = BrowserWindow.getFocusedWindow();
    if (focused !== null) {
        return focused;
    }
    if (lastFocused !== undefined && !lastFocused.isDestroyed()) {
        return lastFocused;
    }
    return BrowserWindow.getAllWindows()[0];
}

function viewFor(window: BrowserWindow | undefined | null): View | undefined {
    return window == null ? undefined : views.get(window.id);
}

// The largest content area a window on this display can have.
function availableContentSize(window: BrowserWindow): Size {
    const workArea = screen.getDisplayMatching(window.getBounds()).workArea;
    const [outerWidth, outerHeight] = window.getSize() as [number, number];
    const [contentWidth, contentHeight] = window.getContentSize() as [number, number];

    return {
        width: workArea.width - (outerWidth - contentWidth),
        height: workArea.height - (outerHeight - contentHeight),
    };
}

async function createWindow(source: {
    name: string;
    filePath: string | undefined;
    bytes: Uint8Array;
}): Promise<void> {
    const window = new BrowserWindow({
        // The real size is set once the renderer tells us how big the image is.
        width: 640,
        height: 480,
        useContentSize: true,
        show: false,
        center: true,
        backgroundColor: BACKGROUND_COLOR,
        title: source.name,
        webPreferences: {
            preload: resolve(__dirname, "preload.js"),
        },
    });

    views.set(window.id, {
        name: source.name,
        filePath: source.filePath,
        imageSize: undefined,
        zoom: 0,
        background: DEFAULT_BACKGROUND,
        hex: undefined,
    });
    window.on("closed", () => {
        views.delete(window.id);
        if (lastFocused === window) {
            lastFocused = undefined;
        }
        buildMenu();
    });

    // A macOS menu key equivalent matches the literal character, so the Zoom In
    // accelerator below only catches the "+" of Cmd+Shift+=. Almost nobody holds
    // shift, so catch the bare Cmd+= here as well.
    window.webContents.on("before-input-event", (event, input) => {
        const plain = input.meta && !input.shift && !input.control && !input.alt;
        if (input.type === "keyDown" && plain && input.key === "=") {
            event.preventDefault();
            setZoom(window, (viewFor(window)?.zoom ?? 0) + 1);
        }
    });

    await window.loadFile(resolve(__dirname, "index.html"));

    const message: ImageMessage = {
        name: source.name,
        bytes: source.bytes,
        mimeType: mimeTypeFor(source.name, source.bytes),
    };
    window.webContents.send("image", message);
}

// The renderer decoded the image. Now we know how big it is, so we can pick a
// zoom, size the window to match, and finally show it.
function onLoaded(window: BrowserWindow, imageSize: Size): void {
    const view = viewFor(window);
    if (view === undefined) {
        return;
    }

    view.imageSize = imageSize;
    view.zoom = fitZoom(imageSize, availableContentSize(window));

    const wanted = zoomedSize(imageSize, view.zoom);
    const available = availableContentSize(window);
    window.setContentSize(
        Math.min(available.width, Math.max(MIN_CONTENT.width, wanted.width)),
        Math.min(available.height, Math.max(MIN_CONTENT.height, wanted.height)));
    window.center();

    // Cascade, so opening several images doesn't hide all but the last.
    if (cascade > 0) {
        const bounds = window.getBounds();
        const offset = (cascade%CASCADE_COUNT)*CASCADE;
        window.setPosition(bounds.x + offset, bounds.y + offset);
    }
    cascade += 1;

    sendView(window, view);
    window.show();
    buildMenu();
}

function sendView(window: BrowserWindow, view: View): void {
    window.webContents.send("view", { zoom: view.zoom, background: view.background });
}

function setZoom(window: BrowserWindow, zoom: number): void {
    const view = viewFor(window);
    if (view === undefined || view.imageSize === undefined) {
        return;
    }

    zoom = clampZoom(zoom);
    if (zoom === view.zoom) {
        return;
    }

    // Zooming in grows the window to fit the bigger image, up to the screen.
    // Zooming out leaves the window alone: the user sized it, and shrinking it
    // out from under them loses that.
    const growing = zoom > view.zoom;
    view.zoom = zoom;

    if (growing) {
        const wanted = zoomedSize(view.imageSize, zoom);
        const available = availableContentSize(window);
        const [contentWidth, contentHeight] = window.getContentSize() as [number, number];
        const width = Math.max(contentWidth, Math.min(wanted.width, available.width));
        const height = Math.max(contentHeight, Math.min(wanted.height, available.height));

        if (width !== contentWidth || height !== contentHeight) {
            window.setContentSize(width, height);
            nudgeOnScreen(window);
        }
    }

    sendView(window, view);
    buildMenu();
}

// Growing a window can push it off the bottom or right of the screen.
function nudgeOnScreen(window: BrowserWindow): void {
    const workArea = screen.getDisplayMatching(window.getBounds()).workArea;
    const bounds = window.getBounds();

    const x = Math.max(workArea.x, Math.min(bounds.x, workArea.x + workArea.width - bounds.width));
    const y = Math.max(workArea.y, Math.min(bounds.y, workArea.y + workArea.height - bounds.height));

    if (x !== bounds.x || y !== bounds.y) {
        window.setPosition(x, y);
    }
}

function setBackground(window: BrowserWindow, background: Background): void {
    const view = viewFor(window);
    if (view === undefined || view.background === background) {
        return;
    }

    view.background = background;
    sendView(window, view);
    buildMenu();
}

async function openFiles(filePaths: readonly string[]): Promise<void> {
    for (const filePath of filePaths) {
        const absolute = resolve(filePath);
        try {
            const bytes = await readFile(absolute);
            await createWindow({ name: basename(absolute), filePath: absolute, bytes });
        } catch (error) {
            dialog.showMessageBox({
                type: "error",
                message: `Can't read ${basename(absolute)}`,
                detail: error instanceof Error ? error.message : String(error),
            });
        }
    }
}

async function openDialog(): Promise<boolean> {
    const result = await dialog.showOpenDialog({
        properties: ["openFile", "multiSelections"],
        filters: [{ name: "Images", extensions: [...IMAGE_EXTENSIONS] }],
    });

    await openFiles(result.filePaths);
    return result.filePaths.length > 0;
}

// Paste opens the clipboard image in a new window, the same as opening a file.
async function paste(): Promise<void> {
    const image = clipboard.readImage();
    if (image.isEmpty()) {
        shell.beep();
        return;
    }

    await createWindow({
        name: "Clipboard",
        filePath: undefined,
        bytes: image.toPNG(),
    });
}

function copyColor(window: BrowserWindow): void {
    const hex = viewFor(window)?.hex;
    if (hex !== undefined) {
        clipboard.writeText(hex);
    }
}

// Rebuilt whenever the menu would show something different: on focus changes,
// and when the zoom or background of the focused window changes.
function buildMenu(): void {
    const view = viewFor(currentWindow());

    const withWindow = (action: (window: BrowserWindow) => void) =>
        (_item: Electron.MenuItem, focused: Electron.BaseWindow | undefined) => {
            const window = focused instanceof BrowserWindow ? focused : currentWindow();
            if (window !== undefined) {
                action(window);
            }
        };

    const template: Electron.MenuItemConstructorOptions[] = [
        { role: "appMenu" },
        {
            label: "File",
            submenu: [
                { label: "Open…", accelerator: "Cmd+O", click: () => void openDialog() },
                { type: "separator" },
                { role: "close" },
            ],
        },
        {
            label: "Edit",
            submenu: [
                {
                    label: "Copy Color",
                    accelerator: "Cmd+C",
                    enabled: view?.hex !== undefined,
                    click: withWindow(copyColor),
                },
                { label: "Paste", accelerator: "Cmd+V", click: () => void paste() },
            ],
        },
        {
            label: "View",
            submenu: [
                {
                    label: "Zoom In",
                    accelerator: "Cmd+Plus",
                    enabled: view !== undefined && view.zoom < MAX_ZOOM,
                    click: withWindow((w) => setZoom(w, (viewFor(w)?.zoom ?? 0) + 1)),
                },
                {
                    label: "Zoom Out",
                    accelerator: "Cmd+-",
                    enabled: view !== undefined && view.zoom > MIN_ZOOM,
                    click: withWindow((w) => setZoom(w, (viewFor(w)?.zoom ?? 0) - 1)),
                },
                { type: "separator" },
                {
                    label: "Background",
                    submenu: BACKGROUNDS.map((background) => ({
                        label: backgroundLabel(background),
                        type: "radio" as const,
                        checked: view?.background === background,
                        enabled: view !== undefined,
                        click: withWindow((w) => setBackground(w, background)),
                    })),
                },
                { type: "separator" },
                { role: "toggleDevTools" },
            ],
        },
        { role: "windowMenu" },
    ];

    Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

ipcMain.on("loaded", (event, size: Size) => {
    const window = BrowserWindow.fromWebContents(event.sender);
    if (window !== null) {
        onLoaded(window, size);
    }
});

ipcMain.on("failed", (event, message: string) => {
    const window = BrowserWindow.fromWebContents(event.sender);
    const view = viewFor(window);
    if (window === null || view === undefined) {
        return;
    }

    window.destroy();
    dialog.showMessageBox({
        type: "error",
        message: `Can't show ${view.name}`,
        detail: message,
    });
});

ipcMain.on("sampled", (event, hex: string | undefined) => {
    const view = viewFor(BrowserWindow.fromWebContents(event.sender));
    if (view === undefined) {
        return;
    }

    // Only the menu cares, and only about whether there's a color at all, so
    // don't rebuild it for every pixel the mouse passes over.
    const wasEnabled = view.hex !== undefined;
    view.hex = hex;
    if (wasEnabled !== (hex !== undefined)) {
        buildMenu();
    }
});

app.on("browser-window-focus", (_event, window) => {
    lastFocused = window;
    buildMenu();
});

// Files opened by double-clicking in the Finder or dragging onto the icon.
const openFileQueue: string[] = [];
app.on("open-file", (event, filePath) => {
    event.preventDefault();
    if (app.isReady()) {
        void openFiles([filePath]);
    } else {
        openFileQueue.push(filePath);
    }
});

app.on("window-all-closed", () => app.quit());

// Show the image the way the file describes it, not the way the display would
// prefer it. Without this, Chromium converts pixels into the display's color
// profile and the color you pick isn't the color in the file.
app.commandLine.appendSwitch("force-color-profile", "srgb");

app.whenReady().then(async () => {
    buildMenu();

    const filePaths = [...filenamesFromArgv(process.argv, app.isPackaged), ...openFileQueue];
    if (filePaths.length > 0) {
        await openFiles(filePaths);
    } else if (!(await openDialog())) {
        // Launched with no arguments and the user canceled the Open dialog.
        app.quit();
    }

    // We're usually launched from a terminal, which otherwise keeps the focus.
    app.focus({ steal: true });
});

// This is a local image, not a browser.
app.on("web-contents-created", (_event, contents) => {
    contents.setWindowOpenHandler(({ url }) => {
        void shell.openExternal(url);
        return { action: "deny" };
    });
});
