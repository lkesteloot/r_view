// Builds the three entry points into dist/. Run with "npm run build".
import * as esbuild from "esbuild";
import { cpSync, mkdirSync } from "node:fs";

const watch = process.argv.includes("--watch");

/** @type {import("esbuild").BuildOptions} */
const common = {
    bundle: true,
    sourcemap: true,
    target: "node20",
    logLevel: "info",
};

const builds = [
    // Main process: owns the command line, the windows, and the menu.
    { ...common, entryPoints: ["src/main/main.ts"], outfile: "dist/main.js",
      platform: "node", format: "cjs", external: ["electron"] },
    // Preload: the only bridge between the main process and the renderer.
    { ...common, entryPoints: ["src/preload/preload.ts"], outfile: "dist/preload.js",
      platform: "node", format: "cjs", external: ["electron"] },
    // Renderer: decodes the image and draws it on a canvas. No Node access.
    { ...common, entryPoints: ["src/renderer/renderer.ts"], outfile: "dist/renderer.js",
      platform: "browser", format: "iife", target: "chrome128" },
];

mkdirSync("dist", { recursive: true });
cpSync("src/renderer/index.html", "dist/index.html");

if (watch) {
    for (const options of builds) {
        const ctx = await esbuild.context(options);
        await ctx.watch();
    }
} else {
    await Promise.all(builds.map((options) => esbuild.build(options)));
}
