import { describe, expect, it } from "vitest";

import { filenamesFromArgv } from "../src/main/commandline.js";

describe("filenamesFromArgv", () => {
    it("skips electron and the script in development", () => {
        expect(filenamesFromArgv(["electron", "dist/main.js", "a.png"], false)).toEqual(["a.png"]);
    });

    it("skips just the binary when packaged", () => {
        expect(filenamesFromArgv(["r_view", "a.png", "b.png"], true)).toEqual(["a.png", "b.png"]);
    });

    it("drops options, including the Finder's process serial number", () => {
        expect(filenamesFromArgv(["r_view", "-psn_0_123", "--foo", "a.png"], true))
            .toEqual(["a.png"]);
    });

    it("handles no filenames", () => {
        expect(filenamesFromArgv(["r_view"], true)).toEqual([]);
    });
});
