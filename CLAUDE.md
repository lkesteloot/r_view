# r_view

A macOS image viewer whose job is to show an image without changing it, and to
report exact pixel colors. Electron and TypeScript. See README.md for what it
does from the user's side; this file is about how it's built and what's easy to
get wrong.

**The governing idea: the color number in the title bar is the number in the file.**
Almost every unusual decision below follows from that. If a change would make a
reported color merely close to the file's, it's the wrong change.

## Commands

```sh
make check              # tsc --noEmit and vitest
make run FILE=foo.png   # run without packaging
make app                # package to build/mac-arm64/r_view.app
make icon               # regenerate icon/r_view.icns after editing draw-icon.ts
make install            # ~/Applications/r_view.app + ~/.local/bin/r_view
```

## Layout

- `src/core/` — no Electron, all the real behavior, all the tests point here.
- `src/main/` — command line, windows, menu. **Owns the zoom and the
  background**, because it needs both to size windows and check menu items.
- `src/preload/` — the IPC bridge and the message types.
- `src/renderer/` — decodes and draws. Owns `document.title`.
- `icon/` — generates the `.icns`.

Data flow: main reads the file → renderer decodes and reports size and whether
the image has transparency → main picks the zoom, sizes the window, shows it →
renderer draws and sets the title. Picks flow back up so Copy Color works.

## Decisions that are load-bearing

**Decoding uses WebCodecs `ImageDecoder`, not a canvas.** A canvas stores colors
premultiplied by alpha, so a round trip through `drawImage`/`getImageData`
corrupts every translucent pixel. Measured on a hand-built PNG: `(32,128,80,36)`
came back `(35,128,78,36)`, and a pixel at alpha 0 lost its RGB entirely.
WebCodecs returns the file's bytes exactly. The canvas path in `decode.ts` is
only a fallback, and it's exact for opaque images, which is most of them.

- `ImageDecoder` needs a **secure context**. It exists over `file://` but is
  `undefined` over `data:` URLs. A test harness that loads a `data:` URL will
  report it missing and quietly fall through to the lossy path.
- On macOS the decoded frame is **BGRA**; `frameToImage` swaps R and B.
- Decode with `colorSpaceConversion: "none"`, and the app launches with
  `force-color-profile=srgb`, so Chromium doesn't convert the file's numbers
  into the display's profile. This means a wide-gamut image looks slightly
  different here than in Preview. That is the intended trade.

**Shrinking happens before compositing, as a separate pass.** `reduce.ts`
averages the image down; `compose.ts` then only ever does block copies. Two
reasons: `compose` stays a simple hot loop, and the checkerboard behind a
transparent image doesn't get blurred along with the image. Don't fold the
averaging into `compose`.

- The average is **alpha-weighted**, so a transparent pixel's color can't bleed
  into its neighbors.
- Averaging is in sRGB, not linear light. Deliberate: it's what Preview,
  Photoshop and browsers do, and an image should shrink here the way it does
  everywhere else.

**The picker reads the original image, never the reduced one.** Zoomed out, the
color reported and the color on screen are genuinely different, and that's
correct — the title bar must name a pixel that exists in the file. `pixelAt`
takes the original image and the zoom.

**Everything is a power of two.** Zoom is an integer exponent (`2^zoom`), the
device pixel ratio is a whole number, so an image pixel either fills a whole
block of device pixels or a whole block averages down to one. On a retina
display, 1:2 needs no averaging at all — device scale is exactly 1, and there
the picker and the screen agree exactly.

**The canvas is snapped to whole device pixels while scrolling.** At a
fractional position the compositor resamples it, which is the exact blurring
this program exists to avoid. Scrolling is the browser's (native two-finger
momentum, system scrollbars): a spacer sized to the zoomed image, and a
viewport-sized canvas whose transform and contents are updated in the *same*
frame so they can't slide against each other.

## Things that bit me

**`BrowserWindow.getFocusedWindow()` returns null whenever the app isn't
frontmost.** Building the menu from it directly makes every item gray out and
every handler silently no-op — Copy Color stops working, zoom stops responding,
with no error anywhere. Use `currentWindow()`, which falls back to the last
focused window. Radio menu items still *look* like they responded, because
macOS toggles their checkmark regardless of the handler, so this failure hides
well.

**A macOS menu key equivalent matches the literal character.** `Cmd+Plus` only
catches ⌘⇧=. Bare ⌘= is handled separately in a `before-input-event` hook. The
two can't double-fire because they're different key events; verify zoom still
advances exactly one step per press if you touch either.

**In an Electron test harness, add `app.on("window-all-closed", () => {})`.**
Electron's default is to quit on *every* platform, so destroying a window
mid-script kills the app and the script hangs with no output.

**`screencapture` doesn't work here** (no screen-recording permission). Use
`webContents.capturePage()` instead, which is better anyway.

## How to actually verify changes

Unit tests cover `core/`. For anything touching pixels or the menu, drive the
real app — this has caught things tests couldn't:

- **Boot the real main process** from a scratch script with
  `require(".../dist/main.js")`, then inspect and click menu items through
  `Menu.getApplicationMenu()`, and send input with
  `webContents.sendInputEvent(...)`. This exercises the actual window sizing,
  menu state, and IPC.
- **Check pixels end to end** with `capturePage()`, then compare the PNG against
  values computed independently. Byte-exactness at 1:1 and the box average when
  zoomed out have both been verified this way, over hundreds of thousands of
  pixels.
- Watch out when writing the comparison script: **JS `Math.round` rounds half
  up, Python's `round` rounds half to even.** That difference alone will show up
  as every blue channel being off by one.

## Icon

Generated, not drawn by hand: edit `icon/draw-icon.ts`, run `make icon`, commit
the `.icns`. `make app` uses the committed file, so building never opens a
window. `make icon` also writes the `icon/r_view.png` that the README embeds.

The geometry is calibrated against Apple's own system icons — an 824×824 body in
1024 (margin 100), corner radius 193, and a black shadow at 19% opacity with
size 14, offset 9, spread 5. The radius is the circular arc that best fits the
shape macOS draws, whose corners are slightly non-circular; `roundRect` can't
draw the real shape, and matching the nominal 185 renders visibly too tight.
The color grid deliberately runs to all four edges and is cut by the corner
curve — an inset grid reads as too small next to system icons.

## Style

Match the surrounding code. Notably:

- Four spaces, double quotes, semicolons, braces always.
- `*` and `/` bind tight, `+` and `-` get spaces: `y*width + x`, `(a + b)/2`.
- Comments say *why*, not what. Several of the decisions above live as comments
  at the top of the file they govern; keep them in sync if the reasoning changes.
- `strict` plus `noUncheckedIndexedAccess`, hence the `!` on indexed reads.
- The title format is typographic: en dash (U+2013) and arrow (U+2192), not
  ASCII. `core/title.ts` is the only place that decides this.
